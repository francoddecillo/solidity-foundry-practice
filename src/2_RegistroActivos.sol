// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RegistroActivos
 * @dev Muestra cómo utilizar diferentes tipos de datos (números, booleanos, direcciones)
 * y cómo inicializarlos al crear el contrato mediante el Constructor.
 * Caso de negocio: Registrar la ficha básica de un activo fijo de la empresa (ej. maquinaria o un inmueble).
 */
contract RegistroActivos {
    // Identificador único del activo (Número entero sin signo)
    uint256 public idActivo;

    // Valor estimado en USD del activo (Número entero)
    uint256 public valorUSD;

    // Indica si el activo ya está completamente depreciado en los libros contables
    bool public estaDepreciado;

    // Dirección (wallet) del empleado responsable de la custodia del activo
    address public custodio;

    /**
     * @dev El constructor inicializa el estado del contrato al momento del despliegue.
     * @param _idActivo Código identificador del activo.
     * @param _valorUSD Valor inicial del activo.
     * @param _custodio Dirección de la cuenta del responsable.
     */
    constructor(uint256 _idActivo, uint256 _valorUSD, address _custodio) {
        idActivo = _idActivo;
        valorUSD = _valorUSD;
        custodio = _custodio;
        estaDepreciado = false; // Comienza sin estar depreciado
    }

    /**
     * @notice Permite depreciar el activo de forma definitiva.
     */
    function depreciarActivo() public {
        estaDepreciado = true;
        valorUSD = 0; // Al depreciarse por completo, su valor contable pasa a 0
    }

    /**
     * @notice Permite reasignar el custodio del activo.
     * @param _nuevoCustodio Dirección de la cuenta del nuevo responsable.
     */
    function reasignarCustodio(address _nuevoCustodio) public {
        custodio = _nuevoCustodio;
    }
}
