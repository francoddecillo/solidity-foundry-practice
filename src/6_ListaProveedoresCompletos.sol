// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

/**
 * @title ListaProveedoresCompletos
 * @dev Enseña cómo combinar Estructuras (structs) con Mappings para gestionar
 * colecciones organizadas de datos complejos en blockchain.
 * Caso de negocio: Un catálogo descentralizado de proveedores de la empresa,
 * donde cada dirección de Ethereum (wallet) corresponde a un proveedor verificado.
 */
contract ListaProveedoresCompletos {
    struct Proveedor {
        string nombre;
        string rutIdentificacion;
        uint256 volumenCompraUSD;
        bool estaActivo;
    }

    // Mapeo: Dirección del Proveedor => Ficha detallada del Proveedor
    mapping(address => Proveedor) public proveedores;
    
    // Dirección del Gerente de Finanzas
    address public gerenteFinanzas;

    modifier soloGerente() {
        require(msg.sender == gerenteFinanzas, "Error: Solo el Gerente de Finanzas puede realizar esto.");
        _;
    }

    constructor() {
        gerenteFinanzas = msg.sender;
    }

    /**
     * @notice Registra un nuevo proveedor en el catálogo o actualiza uno existente.
     * @param _walletProveedor Dirección de Ethereum del proveedor.
     * @param _nombre Nombre comercial.
     * @param _rut RUT o identificador tributario.
     */
    function registrarProveedor(
        address _walletProveedor,
        string memory _nombre,
        string memory _rut
    ) public soloGerente {
        require(_walletProveedor != address(0), "Error: Direccion del proveedor no valida.");
        
        // Asignación directa en el mapeo
        proveedores[_walletProveedor] = Proveedor({
            nombre: _nombre,
            rutIdentificacion: _rut,
            volumenCompraUSD: 0,
            estaActivo: true
        });
    }

    /**
     * @notice Registra una orden de compra, aumentando el volumen comercial acumulado del proveedor.
     * @param _walletProveedor Dirección de Ethereum del proveedor.
     * @param _montoUSD Valor de la compra.
     */
    function registrarCompra(address _walletProveedor, uint256 _montoUSD) public soloGerente {
        // Validación de que el proveedor existe y está activo
        require(proveedores[_walletProveedor].estaActivo, "Error: El proveedor no esta registrado o esta inactivo.");
        
        proveedores[_walletProveedor].volumenCompraUSD += _montoUSD;
    }

    /**
     * @notice Permite desactivar temporal o permanentemente a un proveedor.
     * @param _walletProveedor Dirección de Ethereum del proveedor.
     * @param _estado Activo (true) o Inactivo (false).
     */
    function establecerEstadoProveedor(address _walletProveedor, bool _estado) public soloGerente {
        proveedores[_walletProveedor].estaActivo = _estado;
    }
}
