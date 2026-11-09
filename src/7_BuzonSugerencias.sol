// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BuzonSugerencias
 * @dev Enseña cómo utilizar Listas Dinámicas (Arrays) en Solidity y cómo iterar
 * sobre ellas utilizando bucles (for).
 * Caso de negocio: Un buzón de ideas o sugerencias interno de la empresa, donde los empleados
 * envían propuestas y el resto puede votar para apoyarlas.
 */
contract BuzonSugerencias {
    struct Sugerencia {
        address autor;
        string descripcion;
        uint256 votosApoyo;
        bool estaProcesada;
    }

    // Array dinámico que almacena todas las sugerencias recibidas
    Sugerencia[] public sugerencias;

    // Dirección del encargado de Recursos Humanos (administrador)
    address public encargadoRRHH;

    modifier soloRRHH() {
        require(msg.sender == encargadoRRHH, "Error: Solo el encargado de RRHH puede realizar esta accion.");
        _;
    }

    constructor() {
        encargadoRRHH = msg.sender;
    }

    /**
     * @notice Registra una nueva sugerencia en la blockchain.
     * @param _descripcion Contenido o idea propuesta por el empleado.
     */
    function crearSugerencia(string memory _descripcion) public {
        require(bytes(_descripcion).length > 0, "Error: La sugerencia no puede estar vacia.");

        // Creamos y agregamos el elemento a la lista usando .push()
        sugerencias.push(Sugerencia({
            autor: msg.sender,
            descripcion: _descripcion,
            votosApoyo: 0,
            estaProcesada: false
        }));
    }

    /**
     * @notice Permite a cualquier persona votar para apoyar una sugerencia específica.
     * @param _id Identificador (índice) de la sugerencia en la lista.
     */
    function apoyarSugerencia(uint256 _id) public {
        require(_id < sugerencias.length, "Error: La sugerencia no existe.");
        sugerencias[_id].votosApoyo += 1;
    }

    /**
     * @notice Permite marcar una sugerencia como procesada (revisada).
     * @param _id Identificador (índice) de la sugerencia.
     */
    function procesarSugerencia(uint256 _id) public soloRRHH {
        require(_id < sugerencias.length, "Error: La sugerencia no existe.");
        sugerencias[_id].estaProcesada = true;
    }

    /**
     * @notice Retorna el número total de sugerencias recibidas.
     * @return Cantidad de sugerencias en la lista.
     */
    function obtenerTotalSugerencias() public view returns (uint256) {
        return sugerencias.length;
    }

    /**
     * @notice Cuenta cuántas sugerencias han sido completamente procesadas.
     * @dev Muestra el uso de un bucle "for" para recorrer la lista en memoria.
     * @return totalProcesadas Cantidad de sugerencias procesadas.
     */
    function contarSugerenciasProcesadas() public view returns (uint256 totalProcesadas) {
        uint256 limite = sugerencias.length;
        for (uint256 i = 0; i < limite; i++) {
            if (sugerencias[i].estaProcesada) {
                totalProcesadas++;
            }
        }
    }
}
