// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SeguimientoEnvios
 * @dev Enseña cómo gestionar Máquinas de Estado utilizando Enumeraciones (enums)
 * para representar estados lógicos de un proceso de negocio.
 * Caso de negocio: Sistema de seguimiento logístico de mercancía.
 * El envío pasa por: Creado, EnTransito, Recibido o Cancelado.
 */
contract SeguimientoEnvios {
    // Definición del Enumerador que representa los estados lógicos posibles
    enum EstadoEnvio {
        Creado,      // Equivale internamente a 0
        EnTransito,  // Equivale internamente a 1
        Recibido,    // Equivale internamente a 2
        Cancelado    // Equivale internamente a 3
    }

    struct Envio {
        string codigoSeguimiento;
        address cliente;
        EstadoEnvio estado;
    }

    // Mapeo: ID del Envío => Detalle del Envío
    mapping(uint256 => Envio) public envios;
    
    // Contador para generar IDs únicos de envíos
    uint256 public totalEnvios;

    // Dirección del Administrador Logístico
    address public administradorLogistica;

    modifier soloLogistica() {
        require(msg.sender == administradorLogistica, "Error: Solo el administrador logistico puede cambiar estados.");
        _;
    }

    event EnvioCreado(uint256 indexed idEnvio, string codigoSeguimiento, address cliente);
    event EstadoActualizado(uint256 indexed idEnvio, EstadoEnvio nuevoEstado);

    constructor() {
        administradorLogistica = msg.sender;
    }

    /**
     * @notice Registra un nuevo envío en la red.
     * @param _codigo Código identificador del transportista.
     * @param _cliente Dirección del cliente que recibirá el paquete.
     */
    function crearEnvio(string memory _codigo, address _cliente) public soloLogistica {
        require(_cliente != address(0), "Error: Cliente invalido.");
        require(bytes(_codigo).length > 0, "Error: Codigo de seguimiento vacio.");

        envios[totalEnvios] = Envio({
            codigoSeguimiento: _codigo,
            cliente: _cliente,
            estado: EstadoEnvio.Creado // Estado inicial
        });

        emit EnvioCreado(totalEnvios, _codigo, _cliente);
        totalEnvios++;
    }

    /**
     * @notice Transiciona el estado del envío a 'EnTransito'.
     * @param _id Identificador del envío.
     */
    function despacharEnvio(uint256 _id) public soloLogistica {
        require(_id < totalEnvios, "Error: El envio no existe.");
        Envio storage envio = envios[_id];
        
        require(envio.estado == EstadoEnvio.Creado, "Error: Solo se puede despachar si esta en estado Creado.");
        
        envio.estado = EstadoEnvio.EnTransito;
        emit EstadoActualizado(_id, EstadoEnvio.EnTransito);
    }

    /**
     * @notice Confirma que el paquete fue recibido por el cliente.
     * @param _id Identificador del envío.
     */
    function entregarEnvio(uint256 _id) public soloLogistica {
        require(_id < totalEnvios, "Error: El envio no existe.");
        Envio storage envio = envios[_id];

        require(envio.estado == EstadoEnvio.EnTransito, "Error: El envio debe estar EnTransito para entregarse.");

        envio.estado = EstadoEnvio.Recibido;
        emit EstadoActualizado(_id, EstadoEnvio.Recibido);
    }

    /**
     * @notice Cancela el envío debido a incidencias.
     * @param _id Identificador del envío.
     */
    function cancelarEnvio(uint256 _id) public soloLogistica {
        require(_id < totalEnvios, "Error: El envio no existe.");
        Envio storage envio = envios[_id];

        require(
            envio.estado != EstadoEnvio.Recibido && envio.estado != EstadoEnvio.Cancelado,
            "Error: No se puede cancelar un envio ya recibido o cancelado."
        );

        envio.estado = EstadoEnvio.Cancelado;
        emit EstadoActualizado(_id, EstadoEnvio.Cancelado);
    }
}
