// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ControlAccesoBasico
 * @dev Enseña los conceptos de propiedad de un contrato (Owner) y cómo restringir
 * el acceso a funciones críticas utilizando Modificadores y "require".
 * Caso de negocio: Solo el Gerente General (quien despliega el contrato) puede cambiar
 * la dirección física corporativa registrada en la blockchain.
 */
contract ControlAccesoBasico {
    // Dirección del dueño (Gerente General)
    address public gerenteGeneral;

    // Dirección física de la oficina principal
    string public direccionOficina;

    // Modificador: Una regla de negocio reutilizable que valida condiciones antes de ejecutar una función.
    modifier soloGerente() {
        // require evalúa una condición. Si es falsa, revierte la transacción y devuelve el error especificado.
        require(msg.sender == gerenteGeneral, "Error: Solo el Gerente General puede realizar esta accion.");
        _; // El guion bajo indica dónde se ejecutará el cuerpo de la función original
    }

    /**
     * @dev Configura al creador del contrato como el Gerente General original y define la oficina.
     * @param _direccionInicial Ubicación física inicial de la empresa.
     */
    constructor(string memory _direccionInicial) {
        gerenteGeneral = msg.sender; // msg.sender es la dirección que firma la transacción actual
        direccionOficina = _direccionInicial;
    }

    /**
     * @notice Permite al Gerente General cambiar la ubicación física oficial de la oficina.
     * @dev Utiliza el modificador 'soloGerente' para bloquear llamadas no autorizadas.
     * @param _nuevaDireccion Nueva ubicación de la oficina corporativa.
     */
    function actualizarDireccionOficina(string memory _nuevaDireccion) public soloGerente {
        direccionOficina = _nuevaDireccion;
    }

    /**
     * @notice Permite al Gerente General transferir su rol de gerente a otra dirección.
     * @param _nuevoGerente Dirección de la persona que asumirá la gerencia general.
     */
    function transferirGerencia(address _nuevoGerente) public soloGerente {
        require(_nuevoGerente != address(0), "Error: La nueva direccion no puede ser nula (address 0).");
        gerenteGeneral = _nuevoGerente;
    }
}
