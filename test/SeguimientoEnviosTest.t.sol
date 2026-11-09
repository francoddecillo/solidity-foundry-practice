
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {SeguimientoEnvios} from "../src/10_SeguimientoEnvios.sol";

 contract SeguimientoEnviosTest is Test {

     SeguimientoEnvios seguimiento;

     address cliente = address(0xBEEF);
     address intruso = address(0xBAD);

     // Eventos que vamos a verificar
     event EnvioCreado(
         uint256 indexed idEnvio,
         string codigoSeguimiento,
         address cliente
     );

     event EstadoActualizado(
         uint256 indexed idEnvio,
         SeguimientoEnvios.EstadoEnvio nuevoEstado
     );

     function setUp() public {
         seguimiento = new SeguimientoEnvios();
     }

     // Función auxiliar: crear un envío
     function crearUno() internal {
         seguimiento.crearEnvio("ENV-001", cliente);
     }

     // Función auxiliar: consultar el estado
     function estadoDe(uint256 id)
         internal
         view
         returns (uint8)
     {
         (
             ,
             ,
             SeguimientoEnvios.EstadoEnvio estado
         ) = seguimiento.envios(id);

         return uint8(estado);
     }

     // Función auxiliar: codificar un error
     function errorTexto(string memory mensaje)
         internal
         pure
         returns (bytes memory)
     {
         return abi.encodeWithSignature(
             "Error(string)",
             mensaje
         );
     }

     // TEST 1: Estado inicial
     function testEstadoInicial() public view {
         assertEq(
             seguimiento.administradorLogistica(),
             address(this)
         );

         assertEq(seguimiento.totalEnvios(), 0);
     }

     // TEST 2: Crear envío y comprobar evento
     function testCrearEnvioYEvento() public {
         vm.expectEmit(
             true, false, false, true,
             address(seguimiento)
         );

         emit EnvioCreado(0, "ENV-001", cliente);

         crearUno();

         assertEq(seguimiento.totalEnvios(), 1);

         (
             string memory codigo,
             address destinatario,
             SeguimientoEnvios.EstadoEnvio estado
         ) = seguimiento.envios(0);

         assertEq(codigo, "ENV-001");
         assertEq(destinatario, cliente);
         assertEq(uint8(estado), 0);
     }

     // TEST 3: Cliente inválido
     function testClienteCero() public {
         vm.expectRevert(
             errorTexto("Error: Cliente invalido.")
         );

         seguimiento.crearEnvio(
             "ENV-001",
             address(0)
         );
     }

     // TEST 4: Código de seguimiento vacío
     function testCodigoVacio() public {
         vm.expectRevert(
             errorTexto(
                 "Error: Codigo de seguimiento vacio."
             )
         );

         seguimiento.crearEnvio("", cliente);
     }

     // TEST 5: Intruso intenta crear un envío
     function testIntrusoNoPuedeCrear() public {
         vm.expectRevert(
             errorTexto(
                 "Error: Solo el administrador logistico puede cambiar estados."
             )
         );

         vm.prank(intruso);

         seguimiento.crearEnvio(
             "ENV-001",
             cliente
         );
     }

     // TEST 6: Despachar envío y comprobar evento
     function testDespacharYEvento() public {
         crearUno();

         vm.expectEmit(
             true, false, false, true,
             address(seguimiento)
         );

         emit EstadoActualizado(
             0,
             SeguimientoEnvios.EstadoEnvio.EnTransito
         );

         seguimiento.despacharEnvio(0);

         assertEq(estadoDe(0), 1);
     }

     // TEST 7: No despachar dos veces
     function testNoDespacharDosVeces() public {
         crearUno();
         seguimiento.despacharEnvio(0);

         vm.expectRevert(
             errorTexto(
                 "Error: Solo se puede despachar si esta en estado Creado."
             )
         );

         seguimiento.despacharEnvio(0);
     }

     // TEST 8: No entregar desde Creado
     function testNoEntregarDesdeCreado() public {
         crearUno();

         vm.expectRevert(
             errorTexto(
                 "Error: El envio debe estar EnTransito para entregarse."
             )
         );

         seguimiento.entregarEnvio(0);
     }

     // TEST 9: Entregar envío y comprobar evento
     function testEntregarYEvento() public {
         crearUno();
         seguimiento.despacharEnvio(0);

         vm.expectEmit(
             true, false, false, true,
             address(seguimiento)
         );

         emit EstadoActualizado(
             0,
             SeguimientoEnvios.EstadoEnvio.Recibido
         );

         seguimiento.entregarEnvio(0);

         assertEq(estadoDe(0), 2);
     }

     // TEST 10: Cancelar desde Creado
     function testCancelarDesdeCreado() public {
         crearUno();

         vm.expectEmit(
             true, false, false, true,
             address(seguimiento)
         );

         emit EstadoActualizado(
             0,
             SeguimientoEnvios.EstadoEnvio.Cancelado
         );

         seguimiento.cancelarEnvio(0);

         assertEq(estadoDe(0), 3);
     }

     // TEST 11: Cancelar desde EnTransito
     function testCancelarDesdeTransito() public {
         crearUno();
         seguimiento.despacharEnvio(0);
         seguimiento.cancelarEnvio(0);

         assertEq(estadoDe(0), 3);
     }

     // TEST 12: No cancelar un envío recibido
     function testNoCancelarRecibido() public {
         crearUno();
         seguimiento.despacharEnvio(0);
         seguimiento.entregarEnvio(0);

         vm.expectRevert(
             errorTexto(
                 "Error: No se puede cancelar un envio ya recibido o cancelado."
             )
         );

         seguimiento.cancelarEnvio(0);
     }

     // TEST 13: No cancelar dos veces
     function testNoCancelarDosVeces() public {
         crearUno();
         seguimiento.cancelarEnvio(0);

         vm.expectRevert(
             errorTexto(
                 "Error: No se puede cancelar un envio ya recibido o cancelado."
             )
         );

         seguimiento.cancelarEnvio(0);
     }

     // TEST 14: ID inexistente
     function testEnvioInexistente() public {
         vm.expectRevert(
             errorTexto(
                 "Error: El envio no existe."
             )
         );

         seguimiento.despacharEnvio(999);
     }

     // TEST 15: Intruso intenta cambiar estado
     function testIntrusoNoPuedeDespachar() public {
         crearUno();

         vm.expectRevert(
             errorTexto(
                 "Error: Solo el administrador logistico puede cambiar estados."
             )
         );

         vm.prank(intruso);

         seguimiento.despacharEnvio(0);
     }
 }
