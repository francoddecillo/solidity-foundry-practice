
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {SuscripcionServicio} from
     "../src/15_SuscripcionServicio.sol";

 // Contrato auxiliar: es propietario del SaaS,
 // pero rechaza las transferencias de ETH.
 contract PropietarioQueRechaza {

     SuscripcionServicio public servicio;

     constructor() {
         servicio = new SuscripcionServicio(0.1 ether);
     }

     receive() external payable {
         revert("No acepto Ether");
     }

     function retirar() external {
         servicio.retirarFondosSaaS();
     }
 }

 contract SuscripcionServicioTest is Test {

     SuscripcionServicio servicio;

     address propietario = address(0xCAFE);
     address cliente1 = address(0xA11CE);
     address cliente2 = address(0xB0B);
     address intruso = address(0xBAD);

     uint256 constant PRECIO = 0.1 ether;

     event SuscripcionRenovada(
         address indexed cliente,
         uint256 nuevoVencimiento
     );

     event RetiroGanancias(
         address propietario,
         uint256 monto
     );

     function setUp() public {
         vm.warp(1_000_000);

         vm.deal(cliente1, 10 ether);
         vm.deal(cliente2, 10 ether);
         vm.deal(propietario, 0);

         // El propietario es una cuenta externa.
         vm.prank(propietario);

         servicio = new SuscripcionServicio(PRECIO);
     }

     // Funcion auxiliar: pagar la tarifa original
     function pagar(address cliente) internal {
         vm.prank(cliente);
         servicio.pagarSuscripcion{value: PRECIO}();
     }

     // TEST 1: Configuracion inicial
     function testConfiguracionInicial() public view {
         assertEq(
             servicio.propietarioServicio(),
             propietario
         );

         assertEq(servicio.costoMensual(), PRECIO);

         assertEq(
             servicio.DURACION_MES(),
             30 days
         );

         assertEq(address(servicio).balance, 0);
     }

     // TEST 2: Cliente sin suscripcion
     function testClienteInicialmenteInactivo() public view {
         assertFalse(
             servicio.esSuscripcionActiva(cliente1)
         );

         assertEq(
             servicio.expiracionSuscripcion(cliente1),
             0
         );
     }

     // TEST 3: Primer pago y evento
     function testPrimerPagoYEvento() public {
         uint256 vencimientoEsperado =
             block.timestamp + 30 days;

         vm.expectEmit(
             true, false, false, true,
             address(servicio)
         );

         emit SuscripcionRenovada(
             cliente1,
             vencimientoEsperado
         );

         pagar(cliente1);

         assertTrue(
             servicio.esSuscripcionActiva(cliente1)
         );

         assertEq(
             servicio.expiracionSuscripcion(cliente1),
             vencimientoEsperado
         );

         assertEq(
             address(servicio).balance,
             PRECIO
         );
     }

     // TEST 4: Rechazar un pago insuficiente
     function testRechazarPagoInsuficiente() public {
         vm.expectRevert(
             "Error: Debe enviar el monto exacto de la suscripcion mensual."
         );

         vm.prank(cliente1);

         servicio.pagarSuscripcion{
             value: 0.09 ether
         }();

         assertFalse(
             servicio.esSuscripcionActiva(cliente1)
         );
     }

     // TEST 5: Rechazar un pago excesivo
     function testRechazarPagoExcesivo() public {
         vm.expectRevert(
             "Error: Debe enviar el monto exacto de la suscripcion mensual."
         );

         vm.prank(cliente1);

         servicio.pagarSuscripcion{
             value: 0.11 ether
         }();

         assertEq(address(servicio).balance, 0);
     }

     // TEST 6: Renovar antes del vencimiento
     function testRenovacionAnticipada() public {
         pagar(cliente1);

         uint256 vencimientoAnterior =
             servicio.expiracionSuscripcion(cliente1);

         vm.warp(block.timestamp + 10 days);

         pagar(cliente1);

         uint256 vencimientoNuevo =
             servicio.expiracionSuscripcion(cliente1);

         assertEq(
             vencimientoNuevo,
             vencimientoAnterior + 30 days
         );

         assertEq(
             address(servicio).balance,
             0.2 ether
         );
     }

     // TEST 7: Exactamente al vencer ya esta inactiva
     function testInactivaEnFechaExacta() public {
         pagar(cliente1);

         uint256 vencimiento =
             servicio.expiracionSuscripcion(cliente1);

         vm.warp(vencimiento);

         assertFalse(
             servicio.esSuscripcionActiva(cliente1)
         );
     }

     // TEST 8: Tambien inactiva despues del vencimiento
     function testInactivaDespuesDelVencimiento() public {
         pagar(cliente1);

         uint256 vencimiento =
             servicio.expiracionSuscripcion(cliente1);

         vm.warp(vencimiento + 1);

         assertFalse(
             servicio.esSuscripcionActiva(cliente1)
         );
     }

     // TEST 9: Renovar una suscripcion vencida
     function testRenovarDespuesDeVencer() public {
         pagar(cliente1);

         uint256 vencimientoAnterior =
             servicio.expiracionSuscripcion(cliente1);

         vm.warp(vencimientoAnterior + 7 days);

         assertFalse(
             servicio.esSuscripcionActiva(cliente1)
         );

         uint256 ahora = block.timestamp;

         pagar(cliente1);

         assertEq(
             servicio.expiracionSuscripcion(cliente1),
             ahora + 30 days
         );

         assertTrue(
             servicio.esSuscripcionActiva(cliente1)
         );
     }

     // TEST 10: Las suscripciones son independientes
     function testClientesIndependientes() public {
         pagar(cliente1);

         assertTrue(
             servicio.esSuscripcionActiva(cliente1)
         );

         assertFalse(
             servicio.esSuscripcionActiva(cliente2)
         );

         vm.warp(block.timestamp + 5 days);

         pagar(cliente2);

         assertTrue(
             servicio.esSuscripcionActiva(cliente2)
         );

         assertEq(
             servicio.expiracionSuscripcion(cliente2),
             block.timestamp + 30 days
         );

         assertEq(
             address(servicio).balance,
             0.2 ether
         );
     }

     // TEST 11: Tres pagos acumulan 90 dias
     function testTresPagosAcumulados() public {
         uint256 inicio = block.timestamp;

         pagar(cliente1);
         pagar(cliente1);
         pagar(cliente1);

         assertEq(
             servicio.expiracionSuscripcion(cliente1),
             inicio + 90 days
         );

         assertEq(
             address(servicio).balance,
             0.3 ether
         );
     }

     // TEST 12: Propietario cambia el precio
     function testPropietarioCambiaPrecio() public {
         vm.prank(propietario);

         servicio.cambiarCostoMensual(0.2 ether);

         assertEq(
             servicio.costoMensual(),
             0.2 ether
         );
     }

     // TEST 13: Un intruso no puede cambiar el precio
     function testIntrusoNoPuedeCambiarPrecio() public {
         vm.expectRevert(
             "Error: Solo el propietario del servicio puede realizar esta accion."
         );

         vm.prank(intruso);
         servicio.cambiarCostoMensual(0.2 ether);
     }

     // TEST 14: El precio anterior deja de ser valido
     function testPrecioAnteriorRechazado() public {
         vm.prank(propietario);
         servicio.cambiarCostoMensual(0.2 ether);

         vm.expectRevert(
             "Error: Debe enviar el monto exacto de la suscripcion mensual."
         );

         vm.prank(cliente1);
         servicio.pagarSuscripcion{
             value: 0.1 ether
         }();
     }

     // TEST 15: Pagar con la nueva tarifa
     function testPagarConTarifaActualizada() public {
         pagar(cliente1);

         uint256 vencimientoAnterior =
             servicio.expiracionSuscripcion(cliente1);

         vm.prank(propietario);
         servicio.cambiarCostoMensual(0.2 ether);

         vm.prank(cliente1);
         servicio.pagarSuscripcion{
             value: 0.2 ether
         }();

         assertEq(
             servicio.expiracionSuscripcion(cliente1),
             vencimientoAnterior + 30 days
         );

         assertEq(
             address(servicio).balance,
             0.3 ether
         );
     }

     // TEST 16: El precio cero esta permitido
     function testPrecioCeroPermiteSuscripcionGratis() public {
         vm.prank(propietario);
         servicio.cambiarCostoMensual(0);

         vm.prank(cliente1);
         servicio.pagarSuscripcion{value: 0}();

         assertTrue(
             servicio.esSuscripcionActiva(cliente1)
         );

         assertEq(address(servicio).balance, 0);
     }

     // TEST 17: Retirar ganancias y emitir evento
     function testRetirarGananciasYEvento() public {
         pagar(cliente1);
         pagar(cliente2);

         vm.expectEmit(
             false, false, false, true,
             address(servicio)
         );

         emit RetiroGanancias(
             propietario,
             0.2 ether
         );

         vm.prank(propietario);
         servicio.retirarFondosSaaS();

         assertEq(
             propietario.balance,
             0.2 ether
         );

         assertEq(
             address(servicio).balance,
             0
         );

         // El retiro no cancela las suscripciones
         assertTrue(
             servicio.esSuscripcionActiva(cliente1)
         );

         assertTrue(
             servicio.esSuscripcionActiva(cliente2)
         );
     }

     // TEST 18: Un intruso no puede retirar ganancias
     function testIntrusoNoPuedeRetirar() public {
         pagar(cliente1);

         vm.expectRevert(
             "Error: Solo el propietario del servicio puede realizar esta accion."
         );

         vm.prank(intruso);
         servicio.retirarFondosSaaS();

         assertEq(
             address(servicio).balance,
             PRECIO
         );
     }

     // TEST 19: No retirar si el saldo es cero
     function testNoRetirarSinGanancias() public {
         vm.expectRevert(
             "Error: No hay ganancias para retirar."
         );

         vm.prank(propietario);
         servicio.retirarFondosSaaS();
     }

     // TEST 20: Si el propietario rechaza ETH,
     // la retirada debe fallar
     function testTransferenciaAlPropietarioFallida()
         public
     {
         PropietarioQueRechaza receptor =
             new PropietarioQueRechaza();

         SuscripcionServicio otroServicio =
             receptor.servicio();

         vm.prank(cliente1);

         otroServicio.pagarSuscripcion{
             value: PRECIO
         }();

         vm.expectRevert(
             "Error: El retiro fallo."
         );

         receptor.retirar();

         // Los fondos siguen dentro del contrato
         assertEq(
             address(otroServicio).balance,
             PRECIO
         );

         // La suscripcion tampoco se pierde
         assertTrue(
             otroServicio.esSuscripcionActiva(cliente1)
         );
     }
 }
