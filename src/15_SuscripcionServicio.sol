// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SuscripcionServicio
 * @dev Combina variables de tiempo, mappings y cobro de Ether para crear un modelo de
 * negocio SaaS (Software as a Service) recurrente directamente en la blockchain.
 * Caso de negocio: Un cliente paga un precio mensual en Ether para activar su suscripción.
 * El contrato almacena cuándo expira su membresía y valida si puede acceder al servicio.
 */
contract SuscripcionServicio {
    // Dirección del propietario del servicio SaaS (para retirar las ganancias)
    address public propietarioServicio;

    // Costo mensual del servicio (ej. en wei)
    uint256 public costoMensual;

    // Duración de la membresía: 30 días (30 días * 24 horas * 60 min * 60 seg)
    uint256 public constant DURACION_MES = 30 days;

    // Mapeo: Dirección del Cliente => Timestamp de Expiración de su Suscripción
    mapping(address => uint256) public expiracionSuscripcion;

    event SuscripcionRenovada(address indexed cliente, uint256 nuevoVencimiento);
    event RetiroGanancias(address propietario, uint256 monto);

    modifier soloPropietario() {
        require(
            msg.sender == propietarioServicio, "Error: Solo el propietario del servicio puede realizar esta accion."
        );
        _;
    }

    /**
     * @dev Configura el propietario y el costo mensual de la suscripción.
     * @param _costoMensual Precio de suscripción mensual en wei.
     */
    constructor(uint256 _costoMensual) {
        propietarioServicio = msg.sender;
        costoMensual = _costoMensual;
    }

    /**
     * @notice Permite a un cliente pagar la suscripción mensual en Ether.
     * @dev Si el cliente ya tenía días activos, la nueva suscripción se suma a partir de su fecha de vencimiento actual.
     * Si ya había expirado, se inicia a partir del timestamp del bloque actual.
     */
    function pagarSuscripcion() public payable {
        require(msg.value == costoMensual, "Error: Debe enviar el monto exacto de la suscripcion mensual.");

        uint256 vencimientoActual = expiracionSuscripcion[msg.sender];
        uint256 nuevoVencimiento;

        if (block.timestamp > vencimientoActual) {
            // Si la membresía ya expiró, el nuevo mes inicia hoy
            nuevoVencimiento = block.timestamp + DURACION_MES;
        } else {
            // Si aún está activa, se acumula el mes al vencimiento que ya tenía
            nuevoVencimiento = vencimientoActual + DURACION_MES;
        }

        expiracionSuscripcion[msg.sender] = nuevoVencimiento;

        emit SuscripcionRenovada(msg.sender, nuevoVencimiento);
    }

    /**
     * @notice Permite validar si un cliente tiene acceso activo al servicio SaaS.
     * @param _cliente Dirección de la cuenta del cliente a evaluar.
     * @return true si la suscripción está activa (su fecha de vencimiento es mayor que la hora actual), false de lo contrario.
     */
    function esSuscripcionActiva(address _cliente) public view returns (bool) {
        return expiracionSuscripcion[_cliente] > block.timestamp;
    }

    /**
     * @notice Permite al propietario del servicio retirar los fondos recaudados por suscripciones.
     */
    function retirarFondosSaaS() public soloPropietario {
        uint256 balance = address(this).balance;
        require(balance > 0, "Error: No hay ganancias para retirar.");

        (bool exito,) = propietarioServicio.call{value: balance}("");
        require(exito, "Error: El retiro fallo.");

        emit RetiroGanancias(propietarioServicio, balance);
    }

    /**
     * @notice Permite al propietario cambiar la tarifa de suscripción para nuevos pagos.
     * @param _nuevoCosto Nuevo precio en wei.
     */
    function cambiarCostoMensual(uint256 _nuevoCosto) public soloPropietario {
        costoMensual = _nuevoCosto;
    }
}
