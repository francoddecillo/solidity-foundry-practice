// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CajaChica
 * @dev Enseña cómo gestionar fondos reales de criptomonedas (Ether) en Solidity
 * utilizando la palabra clave "payable" y las funciones de recepción automática.
 * Caso de negocio: Una caja chica corporativa para financiar gastos menores de oficina.
 * Los directivos pueden depositar Ether y el administrador puede retirar montos específicos.
 */
contract CajaChica {
    // Dirección del administrador de la caja chica
    address public administrador;
    
    // Límite de retiro máximo por transacción para control de riesgo
    uint256 public limiteRetiroMaximo;

    // Modificador para restringir funciones únicamente al administrador
    modifier soloAdministrador() {
        require(msg.sender == administrador, "Error: Solo el administrador de la caja chica puede realizar esto.");
        _;
    }

    /**
     * @dev Constructor que define al administrador y el límite de retiro.
     * @param _limiteRetiroMaximo Monto máximo expresado en wei (1 Ether = 10^18 wei).
     */
    constructor(uint256 _limiteRetiroMaximo) {
        administrador = msg.sender;
        limiteRetiroMaximo = _limiteRetiroMaximo;
    }

    /**
     * @notice Función especial para permitir al contrato recibir Ether directamente.
     * @dev Se ejecuta cuando alguien envía Ether a la dirección del contrato sin especificar datos.
     */
    receive() external payable {}

    /**
     * @notice Permite al administrador retirar una cantidad de Ether para pagar un gasto de oficina.
     * @param _monto Cantidad de wei a retirar.
     * @param _destinatario Dirección a la que se le enviarán los fondos.
     */
    function retirarFondos(uint256 _monto, address payable _destinatario) public soloAdministrador {
        require(_monto <= limiteRetiroMaximo, "Error: El monto supera el limite de retiro permitido.");
        require(_monto <= address(this).balance, "Error: Fondos insuficientes en la caja chica.");
        require(_destinatario != address(0), "Error: Direccion de destinatario no valida.");

        // Envío seguro de Ether usando .call
        (bool exito, ) = _destinatario.call{value: _monto}("");
        require(exito, "Error: La transferencia fallo.");
    }

    /**
     * @notice Permite al administrador ajustar el límite máximo de retiro.
     * @param _nuevoLimite Nuevo límite en wei.
     */
    function cambiarLimiteRetiro(uint256 _nuevoLimite) public soloAdministrador {
        limiteRetiroMaximo = _nuevoLimite;
    }

    /**
     * @notice Consulta el saldo actual en Ether de la caja chica.
     * @return El balance del contrato en wei.
     */
    function obtenerBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
