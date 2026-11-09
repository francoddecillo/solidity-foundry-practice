// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ContratoMultifirmaLigero
 * @dev Enseña cómo orquestar transacciones complejas que involucran aprobaciones multipartitas
 * (multifirma), uno de los pilares de la seguridad empresarial en Web3.
 * Caso de negocio: Una tesorería empresarial que solo libera fondos si una propuesta de retiro
 * es aprobada por al menos dos directores diferentes autorizados en la lista.
 */
contract ContratoMultifirmaLigero {
    struct PropuestaRetiro {
        address payable destinatario;
        uint256 monto;
        uint256 cantidadAprobaciones;
        bool ejecutada;
    }

    // Directores oficiales de la firma
    address public director1;
    address public director2;
    address public director3;

    // Registro de propuestas de retiro
    PropuestaRetiro[] public propuestas;

    // Mapeo: ID Propuesta => Wallet Director => Si ya aprobó (true/false)
    mapping(uint256 => mapping(address => bool)) public aprobacionesPorPropuesta;

    modifier soloDirector() {
        require(
            msg.sender == director1 || msg.sender == director2 || msg.sender == director3,
            "Error: Acceso denegado. Solo los directores autorizados pueden llamar a esta funcion."
        );
        _;
    }

    event PropuestaCreada(uint256 idPropuesta, address destinatario, uint256 monto);
    event PropuestaAprobada(uint256 idPropuesta, address director);
    event TransaccionEjecutada(uint256 idPropuesta, address destinatario, uint256 monto);

    /**
     * @dev Registra a los tres directores autorizados.
     */
    constructor(address _director1, address _director2, address _director3) {
        require(
            _director1 != address(0) && _director2 != address(0) && _director3 != address(0),
            "Error: Direcciones invalidas."
        );
        director1 = _director1;
        director2 = _director2;
        director3 = _director3;
    }

    /**
     * @notice Permite depositar fondos al contrato de forma directa.
     */
    receive() external payable {}

    /**
     * @notice Crea una propuesta para realizar un retiro de la tesorería.
     * @param _destinatario Cuenta que recibirá el Ether.
     * @param _monto Monto a transferir en wei.
     */
    function crearPropuestaRetiro(address payable _destinatario, uint256 _monto) public soloDirector {
        require(_destinatario != address(0), "Error: Destinatario invalido.");
        require(_monto <= address(this).balance, "Error: El monto de la propuesta supera el saldo disponible.");

        propuestas.push(
            PropuestaRetiro({destinatario: _destinatario, monto: _monto, cantidadAprobaciones: 0, ejecutada: false})
        );

        emit PropuestaCreada(propuestas.length - 1, _destinatario, _monto);
    }

    /**
     * @notice Aprueba una propuesta de retiro existente.
     * @param _idPropuesta Identificador del índice de la propuesta.
     */
    function aprobarPropuesta(uint256 _idPropuesta) public soloDirector {
        require(_idPropuesta < propuestas.length, "Error: La propuesta no existe.");
        PropuestaRetiro storage propuesta = propuestas[_idPropuesta];

        require(!propuesta.ejecutada, "Error: La propuesta ya fue ejecutada.");
        require(
            !aprobacionesPorPropuesta[_idPropuesta][msg.sender], "Error: Ya has aprobado esta propuesta previamente."
        );

        aprobacionesPorPropuesta[_idPropuesta][msg.sender] = true;
        propuesta.cantidadAprobaciones++;

        emit PropuestaAprobada(_idPropuesta, msg.sender);
    }

    /**
     * @notice Ejecuta la propuesta de retiro si ya tiene al menos 2 aprobaciones de directores.
     * @param _idPropuesta Identificador del índice de la propuesta.
     */
    function ejecutarRetiro(uint256 _idPropuesta) public soloDirector {
        require(_idPropuesta < propuestas.length, "Error: La propuesta no existe.");
        PropuestaRetiro storage propuesta = propuestas[_idPropuesta];

        require(!propuesta.ejecutada, "Error: La propuesta ya fue ejecutada.");
        require(
            propuesta.cantidadAprobaciones >= 2, "Error: La propuesta requiere al menos 2 aprobaciones para ejecutarse."
        );
        require(propuesta.monto <= address(this).balance, "Error: Saldo insuficiente en el contrato para transferir.");

        propuesta.ejecutada = true;

        (bool exito,) = propuesta.destinatario.call{value: propuesta.monto}("");
        require(exito, "Error: La transferencia fallo.");

        emit TransaccionEjecutada(_idPropuesta, propuesta.destinatario, propuesta.monto);
    }

    /**
     * @notice Retorna la cantidad de propuestas registradas.
     */
    function obtenerTotalPropuestas() public view returns (uint256) {
        return propuestas.length;
    }
}
