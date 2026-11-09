// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RegistroProveedores
 * @dev Enseña cómo agrupar múltiples tipos de datos relacionados bajo un mismo objeto
 * utilizando Estructuras (structs).
 * Caso de negocio: Registrar la ficha técnica y comercial de un proveedor único de la empresa.
 */
contract RegistroProveedores {
    // Estructura que define la información de un Proveedor
    struct Proveedor {
        string nombre;
        string rutIdentificacion; // Identificador fiscal
        uint256 volumenCompraAcumulado; // Monto acumulado en compras en USD
        bool estaVerificado;
    }

    // Variable de estado que guarda la ficha del proveedor registrado
    Proveedor public proveedorRegistrado;

    // Dirección del administrador de compras de la empresa
    address public administradorCompras;

    modifier soloAdministrador() {
        require(msg.sender == administradorCompras, "Error: Solo el administrador de compras puede realizar esto.");
        _;
    }

    constructor() {
        administradorCompras = msg.sender;
    }

    /**
     * @notice Registra los datos del proveedor por primera vez.
     * @param _nombre Nombre comercial.
     * @param _rut Identificador tributario oficial.
     */
    function registrarProveedor(string memory _nombre, string memory _rut) public soloAdministrador {
        // Inicialización y guardado de la estructura en la variable de estado
        proveedorRegistrado = Proveedor({
            nombre: _nombre,
            rutIdentificacion: _rut,
            volumenCompraAcumulado: 0,
            estaVerificado: true
        });
    }

    /**
     * @notice Registra una nueva compra al proveedor, acumulando el monto al volumen histórico.
     * @param _montoUSD Valor de la nueva compra en USD.
     */
    function registrarCompra(uint256 _montoUSD) public soloAdministrador {
        require(proveedorRegistrado.estaVerificado, "Error: El proveedor no esta verificado o no esta registrado.");
        proveedorRegistrado.volumenCompraAcumulado += _montoUSD;
    }

    /**
     * @notice Permite dar de baja o verificar la cuenta del proveedor.
     * @param _estado Nuevo estado de verificación.
     */
    function establecerVerificacion(bool _estado) public soloAdministrador {
        proveedorRegistrado.estaVerificado = _estado;
    }
}
