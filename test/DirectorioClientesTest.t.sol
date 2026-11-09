
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {DirectorioClientes} from "../src/5_DirectorioClientes.sol";

 contract DirectorioClientesTest is Test {

     DirectorioClientes directorio;

     address clienteA = address(0x1111);
     address clienteB = address(0x2222);
     address intruso = address(0x3333);

     function setUp() public {
         directorio = new DirectorioClientes();
     }

     // TEST 1: Verificar analista inicial
     function testAnalistaInicial() public view {
         assertEq(
             directorio.analistaRiesgo(),
             address(this)
         );
     }

     // TEST 2: Cliente sin registrar
     function testClienteSinRegistrar() public view {
         assertEq(
             directorio.calificacionCrediticia(clienteA),
             0
         );

         assertFalse(
             directorio.esAptoParaCredito(clienteA)
         );
     }

     // TEST 3: Registrar dos clientes
     function testDosClientes() public {
         directorio.actualizarCalificacion(clienteA, 85);
         directorio.actualizarCalificacion(clienteB, 45);

         assertEq(
             directorio.calificacionCrediticia(clienteA),
             85
         );

         assertEq(
             directorio.calificacionCrediticia(clienteB),
             45
         );

         assertTrue(
             directorio.esAptoParaCredito(clienteA)
         );

         assertFalse(
             directorio.esAptoParaCredito(clienteB)
         );
     }

     // TEST 4: Actualizar puntaje de un cliente
     function testActualizarCalificacion() public {
         directorio.actualizarCalificacion(clienteB, 45);
         directorio.actualizarCalificacion(clienteB, 70);

         assertEq(
             directorio.calificacionCrediticia(clienteB),
             70
         );

         assertTrue(
             directorio.esAptoParaCredito(clienteB)
         );
     }

     // TEST 5: Limite maximo permitido
     function testLimiteCien() public {
         directorio.actualizarCalificacion(clienteA, 100);

         assertEq(
             directorio.calificacionCrediticia(clienteA),
             100
         );

         vm.expectRevert(
             abi.encodeWithSignature(
                 "Error(string)",
                 "Error: La calificacion maxima permitida es 100."
             )
         );

         directorio.actualizarCalificacion(clienteA, 101);
     }

     // TEST 6: Direccion cero
     function testDireccionCero() public {
         vm.expectRevert(
             abi.encodeWithSignature(
                 "Error(string)",
                 "Error: Direccion de cliente no valida."
             )
         );

         directorio.actualizarCalificacion(address(0), 85);
     }

     // TEST 7: Acceso no autorizado
     function testIntrusoNoPuedeActualizar() public {
         vm.prank(intruso);

         vm.expectRevert(
             abi.encodeWithSignature(
                 "Error(string)",
                 "Error: Solo el analista de riesgos puede actualizar calificaciones."
             )
         );

         directorio.actualizarCalificacion(clienteA, 99);
     }
 }
