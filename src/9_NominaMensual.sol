// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NominaMensual
 * @dev Enseña el uso de Eventos (events) para notificar actividades en el exterior
 * de la blockchain y cómo realizar pagos directos a empleados.
 * Caso de negocio: Un sistema descentralizado para que el departamento de Finanzas pague
 * el salario mensual de los colaboradores del proyecto y registre de forma transparente la bitácora.
 */
contract NominaMensual {
    // Dirección del Tesorero de la empresa
    address public tesorero;

    // Declaración de Eventos: Sirven como logs inmutables que las aplicaciones externas (ej. frontend) leen.
    event SalarioPagado(address indexed empleado, uint256 monto, uint256 fecha);
    event FondosRecibidos(address indexed remitente, uint256 monto);

    modifier soloTesorero() {
        require(msg.sender == tesorero, "Error: Solo el Tesorero puede realizar pagos.");
        _;
    }

    constructor() {
        tesorero = msg.sender;
    }

    /**
     * @notice Permite al tesorero depositar fondos iniciales en el contrato de nómina.
     */
    function depositarFondos() public payable soloTesorero {
        require(msg.value > 0, "Error: Debe depositar un monto mayor a cero.");
        emit FondosRecibidos(msg.sender, msg.value);
    }

    /**
     * @notice Paga el salario en Ether a un empleado desde los fondos acumulados del contrato.
     * @param _empleado Dirección de la wallet del colaborador.
     * @param _salario Monto del sueldo en wei.
     */
    function pagarSalario(address payable _empleado, uint256 _salario) public soloTesorero {
        require(_empleado != address(0), "Error: Direccion de empleado no valida.");
        require(_salario <= address(this).balance, "Error: Fondos insuficientes en el contrato de nomina.");

        // Ejecutar el pago de forma segura
        (bool exito,) = _empleado.call{value: _salario}("");
        require(exito, "Error: La transferencia de sueldo fallo.");

        // Emitir el evento de auditoría contable
        emit SalarioPagado(_empleado, _salario, block.timestamp);
    }

    /**
     * @notice Consulta el saldo actual disponible en el contrato de nómina.
     * @return Balance en wei.
     */
    function obtenerFondosDisponibles() public view returns (uint256) {
        return address(this).balance;
    }
}
