// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DirectorioClientes
 * @dev Enseña cómo utilizar Tablas Hash o Diccionarios (mappings) en Solidity para buscar
 * valores de forma ultra rápida (tiempo constante O(1)) utilizando una llave.
 * Caso de negocio: Administrar la calificación crediticia interna de clientes (ej. puntaje de 1 a 100)
 * indexado por su dirección pública de Ethereum (wallet).
 */
contract DirectorioClientes {
    // Mapping: Llave (dirección del cliente) => Valor (calificación crediticia 0-100)
    mapping(address => uint256) public calificacionCrediticia;
    
    // Dirección del analista de riesgos (administrador)
    address public analistaRiesgo;

    modifier soloAnalista() {
        require(msg.sender == analistaRiesgo, "Error: Solo el analista de riesgos puede actualizar calificaciones.");
        _;
    }

    constructor() {
        analistaRiesgo = msg.sender;
    }

    /**
     * @notice Registra o actualiza la calificación crediticia de un cliente específico.
     * @param _cliente Dirección de la cuenta del cliente.
     * @param _calificacion Puntaje asignado (ej. 1 a 100).
     */
    function actualizarCalificacion(address _cliente, uint256 _calificacion) public soloAnalista {
        require(_cliente != address(0), "Error: Direccion de cliente no valida.");
        require(_calificacion <= 100, "Error: La calificacion maxima permitida es 100.");
        
        calificacionCrediticia[_cliente] = _calificacion;
    }

    /**
     * @notice Retorna si un cliente es elegible para crédito comercial (calificación mayor o igual a 70).
     * @param _cliente Dirección de la cuenta del cliente.
     * @return true si es elegible, false en caso contrario.
     */
    function esAptoParaCredito(address _cliente) public view returns (bool) {
        uint256 score = calificacionCrediticia[_cliente];
        return score >= 70;
    }
}
