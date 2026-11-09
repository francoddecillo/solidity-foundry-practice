// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AlmacenamientoSimple
 * @dev Este contrato enseña el concepto más básico de Solidity: guardar un dato en la blockchain (Storage).
 * Caso de negocio: Registrar y actualizar el nombre oficial de la organización o empresa.
 */
contract AlmacenamientoSimple {
    // Variable de estado: se almacena permanentemente en la blockchain.
    // Al ser "public", Solidity genera automáticamente una función de lectura (get).
    string public nombreEmpresa;

    /**
     * @notice Permite actualizar el nombre de la empresa.
     * @param _nuevoNombre El nuevo nombre que se desea registrar.
     */
    function establecerNombre(string memory _nuevoNombre) public {
        nombreEmpresa = _nuevoNombre;
    }

    /**
     * @notice Retorna explícitamente el nombre de la empresa.
     * @dev Aunque "nombreEmpresa" ya es pública y tiene un lector automático, esta función
     * sirve para ilustrar cómo retornar datos desde Solidity.
     * @return El nombre actual de la empresa.
     */
    function obtenerNombre() public view returns (string memory) {
        return nombreEmpresa;
    }
}
