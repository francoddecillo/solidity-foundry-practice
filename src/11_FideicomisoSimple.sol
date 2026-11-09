// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FideicomisoSimple
 * @dev Enseña a utilizar marcas de tiempo (`block.timestamp`) en Solidity
 * para establecer condiciones temporales e inmutables.
 * Caso de negocio: Un contrato de garantía (Escrow) de compraventa.
 * El comprador deposita Ether en el contrato. El vendedor puede retirar los fondos
 * solo si el comprador confirma la entrega o si expira el plazo máximo (ej. 30 días)
 * sin que el comprador haya solicitado un reembolso.
 */
contract FideicomisoSimple {
    address public comprador;
    address payable public vendedor;
    address public mediador; // En caso de disputas
    
    uint256 public fechaLimiteReclamacion; // Timestamp limite
    uint256 public montoFideicomiso;
    
    // Estados del fideicomiso
    bool public estaCompletado;
    bool public fondosReembolsados;

    event FondosLiberados(address destinatario, uint256 monto);
    event FondosReembolsados(address destinatario, uint256 monto);

    /**
     * @dev Configura los participantes y el plazo límite del acuerdo.
     * @param _vendedor Dirección de la cuenta del vendedor que recibirá los fondos.
     * @param _mediador Cuenta de un tercero de confianza para resolver disputas.
     * @param _duracionSegundos Plazo de tiempo en segundos (ej. 86400 para 1 día).
     */
    constructor(
        address payable _vendedor,
        address _mediador,
        uint256 _duracionSegundos
    ) payable {
        require(msg.value > 0, "Error: Debe depositar Ether para inicializar el fideicomiso.");
        require(_vendedor != address(0) && _mediador != address(0), "Error: Direcciones invalidas.");
        require(_vendedor != msg.sender, "Error: El comprador no puede ser el vendedor.");

        comprador = msg.sender;
        vendedor = _vendedor;
        mediador = _mediador;
        montoFideicomiso = msg.value;
        fechaLimiteReclamacion = block.timestamp + _duracionSegundos;
        estaCompletado = false;
        fondosReembolsados = false;
    }

    /**
     * @notice Permite al comprador liberar los fondos inmediatamente al vendedor.
     */
    function liberarFondosComprador() public {
        require(msg.sender == comprador, "Error: Solo el comprador puede liberar de forma voluntaria.");
        require(!estaCompletado && !fondosReembolsados, "Error: El fideicomiso ya ha finalizado.");

        estaCompletado = true;
        (bool exito, ) = vendedor.call{value: montoFideicomiso}("");
        require(exito, "Error: La transferencia fallo.");

        emit FondosLiberados(vendedor, montoFideicomiso);
    }

    /**
     * @notice Permite al vendedor retirar los fondos si ha expirado el plazo de reclamación sin disputas.
     */
    function retirarPorVencimientoVendedor() public {
        require(msg.sender == vendedor, "Error: Solo el vendedor puede invocar esta funcion.");
        require(!estaCompletado && !fondosReembolsados, "Error: El fideicomiso ya ha finalizado.");
        require(block.timestamp > fechaLimiteReclamacion, "Error: El plazo de reclamacion aun no ha expirado.");

        estaCompletado = true;
        (bool exito, ) = vendedor.call{value: montoFideicomiso}("");
        require(exito, "Error: La transferencia fallo.");

        emit FondosLiberados(vendedor, montoFideicomiso);
    }

    /**
     * @notice Permite al mediador resolver una disputa reembolsando al comprador o liberando al vendedor.
     * @param _aprobarVendedor Si es true, libera al vendedor; si es false, reembolsa al comprador.
     */
    function resolverDisputaMediador(bool _aprobarVendedor) public {
        require(msg.sender == mediador, "Error: Solo el mediador puede resolver la disputa.");
        require(!estaCompletado && !fondosReembolsados, "Error: El fideicomiso ya ha finalizado.");

        if (_aprobarVendedor) {
            estaCompletado = true;
            (bool exito, ) = vendedor.call{value: montoFideicomiso}("");
            require(exito, "Error: La transferencia fallo.");
            emit FondosLiberados(vendedor, montoFideicomiso);
        } else {
            fondosReembolsados = true;
            (bool exito, ) = payable(comprador).call{value: montoFideicomiso}("");
            require(exito, "Error: El reembolso fallo.");
            emit FondosReembolsados(comprador, montoFideicomiso);
        }
    }
}
