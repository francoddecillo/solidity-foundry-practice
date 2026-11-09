// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RepartoDividendos
 * @dev Enseña cómo realizar operaciones matemáticas en Solidity de forma segura
 * (evitando desbordamientos y considerando que no existen números decimales/punto flotante).
 * Caso de negocio: Repartir de manera automática cualquier depósito que llegue al contrato
 * entre tres socios fundadores según su porcentaje accionario (Socio A: 50%, Socio B: 30%, Socio C: 20%).
 */
contract RepartoDividendos {
    // Direcciones de las cuentas de los tres socios
    address payable public socioA;
    address payable public socioB;
    address payable public socioC;

    // Constantes que representan los porcentajes en base 100
    uint256 public constant PORCENTAJE_A = 50;
    uint256 public constant PORCENTAJE_B = 30;
    uint256 public constant PORCENTAJE_C = 20;

    event DividendosRepartidos(uint256 montoTotal, uint256 cuotaA, uint256 cuotaB, uint256 cuotaC);

    /**
     * @dev Configura las wallets de los socios fundadores.
     */
    constructor(address payable _socioA, address payable _socioB, address payable _socioC) {
        require(
            _socioA != address(0) && _socioB != address(0) && _socioC != address(0), "Error: Direcciones invalidas."
        );
        socioA = _socioA;
        socioB = _socioB;
        socioC = _socioC;
    }

    /**
     * @notice Permite depositar Ether al contrato y repartirlo de forma inmediata e ineludible.
     */
    function recibirYRepartir() public payable {
        uint256 montoTotal = msg.value;
        require(montoTotal > 100 wei, unicode"Error: El monto depositado es demasiado pequeño.");

        // Cálculo de las cuotas utilizando multiplicación antes de la división
        // En Solidity no hay floats, por lo que (monto * porcentaje) / 100 es el estándar
        uint256 cuotaA = (montoTotal * PORCENTAJE_A) / 100;
        uint256 cuotaB = (montoTotal * PORCENTAJE_B) / 100;

        // Para evitar pérdida por decimales de redondeo, el último socio recibe la diferencia restante
        uint256 cuotaC = montoTotal - cuotaA - cuotaB;

        // Ejecutar las transferencias
        (bool exitoA,) = socioA.call{value: cuotaA}("");
        (bool exitoB,) = socioB.call{value: cuotaB}("");
        (bool exitoC,) = socioC.call{value: cuotaC}("");

        require(exitoA && exitoB && exitoC, "Error: Fallo al transferir a uno de los socios.");

        emit DividendosRepartidos(montoTotal, cuotaA, cuotaB, cuotaC);
    }

    /**
     * @dev Fallback para recibir fondos si se le envía Ether directamente sin invocar la función.
     */
    receive() external payable {
        recibirYRepartir();
    }
}
