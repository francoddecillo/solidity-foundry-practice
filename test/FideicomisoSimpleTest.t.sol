
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {FideicomisoSimple} from "../src/11_FideicomisoSimple.sol";

 contract FideicomisoSimpleTest is Test {

     FideicomisoSimple fideicomiso;

     address comprador = address(0xA11CE);
     address payable vendedor = payable(address(0xBEEF));
     address mediador = address(0xCAFE);
     address intruso = address(0xBAD);

     event FondosLiberados(address destinatario, uint256 monto);
     event FondosReembolsados(address destinatario, uint256 monto);

     function setUp() public {
         // Entregamos 10 ETH ficticios al comprador
         vm.deal(comprador, 10 ether);
         vm.deal(vendedor, 0);

         // Simulamos que el comprador despliega el contrato
         vm.prank(comprador);

         fideicomiso = new FideicomisoSimple{value: 1 ether}(
             vendedor,
             mediador,
             1 days
         );
     }

     // Funcion auxiliar para comprobar mensajes de error
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
         assertEq(fideicomiso.comprador(), comprador);
         assertEq(fideicomiso.vendedor(), vendedor);
         assertEq(fideicomiso.mediador(), mediador);
         assertEq(fideicomiso.montoFideicomiso(), 1 ether);
         assertEq(address(fideicomiso).balance, 1 ether);

         assertEq(
             fideicomiso.fechaLimiteReclamacion(),
             block.timestamp + 1 days
         );

         assertFalse(fideicomiso.estaCompletado());
         assertFalse(fideicomiso.fondosReembolsados());
     }

     // TEST 2: No se puede desplegar sin ETH
     function testConstructorSinEther() public {
         vm.expectRevert(
             errorTexto(
                 "Error: Debe depositar Ether para inicializar el fideicomiso."
             )
         );

         vm.prank(comprador);

         new FideicomisoSimple{value: 0}(
             vendedor,
             mediador,
             1 days
         );
     }

     // TEST 3: No se admite vendedor cero
     function testConstructorVendedorCero() public {
         vm.expectRevert(
             errorTexto("Error: Direcciones invalidas.")
         );

         vm.prank(comprador);

         new FideicomisoSimple{value: 1 ether}(
             payable(address(0)),
             mediador,
             1 days
         );
     }

     // TEST 4: Comprador y vendedor no pueden ser iguales
     function testCompradorNoPuedeSerVendedor() public {
         vm.expectRevert(
             errorTexto(
                 "Error: El comprador no puede ser el vendedor."
             )
         );

         vm.prank(comprador);

         new FideicomisoSimple{value: 1 ether}(
             payable(comprador),
             mediador,
             1 days
         );
     }

     // TEST 5: Liberacion voluntaria y evento
     function testLiberacionVoluntariaYEvento() public {
         vm.expectEmit(
             false, false, false, true,
             address(fideicomiso)
         );

         emit FondosLiberados(vendedor, 1 ether);

         vm.prank(comprador);
         fideicomiso.liberarFondosComprador();

         assertTrue(fideicomiso.estaCompletado());
         assertFalse(fideicomiso.fondosReembolsados());
         assertEq(vendedor.balance, 1 ether);
         assertEq(address(fideicomiso).balance, 0);
     }

     // TEST 6: No se pueden liberar los fondos dos veces
     function testNoLiberarDosVeces() public {
         vm.prank(comprador);
         fideicomiso.liberarFondosComprador();

         vm.expectRevert(
             errorTexto(
                 "Error: El fideicomiso ya ha finalizado."
             )
         );

         vm.prank(comprador);
         fideicomiso.liberarFondosComprador();
     }

     // TEST 7: Intruso no puede liberar los fondos
     function testIntrusoNoPuedeLiberar() public {
         vm.expectRevert(
             errorTexto(
                 "Error: Solo el comprador puede liberar de forma voluntaria."
             )
         );

         vm.prank(intruso);
         fideicomiso.liberarFondosComprador();
     }

     // TEST 8: Vendedor no puede retirar antes del plazo
     function testVendedorAntesDelPlazo() public {
         vm.expectRevert(
             errorTexto(
                 "Error: El plazo de reclamacion aun no ha expirado."
             )
         );

         vm.prank(vendedor);
         fideicomiso.retirarPorVencimientoVendedor();
     }

     // TEST 9: Exactamente en el vencimiento no alcanza
     function testVendedorEnFechaLimite() public {
         vm.warp(
             fideicomiso.fechaLimiteReclamacion()
         );

         vm.expectRevert(
             errorTexto(
                 "Error: El plazo de reclamacion aun no ha expirado."
             )
         );

         vm.prank(vendedor);
         fideicomiso.retirarPorVencimientoVendedor();
     }

     // TEST 10: Retiro exitoso despues del vencimiento
     function testRetiroPorVencimientoYEvento() public {
         vm.warp(
             fideicomiso.fechaLimiteReclamacion() + 1
         );

         vm.expectEmit(
             false, false, false, true,
             address(fideicomiso)
         );

         emit FondosLiberados(vendedor, 1 ether);

         vm.prank(vendedor);
         fideicomiso.retirarPorVencimientoVendedor();

         assertTrue(fideicomiso.estaCompletado());
         assertEq(vendedor.balance, 1 ether);
         assertEq(address(fideicomiso).balance, 0);
     }

     // TEST 11: Un intruso no puede retirar al vencimiento
     function testIntrusoNoPuedeRetirar() public {
         vm.warp(
             fideicomiso.fechaLimiteReclamacion() + 1
         );

         vm.expectRevert(
             errorTexto(
                 "Error: Solo el vendedor puede invocar esta funcion."
             )
         );

         vm.prank(intruso);
         fideicomiso.retirarPorVencimientoVendedor();
     }

     // TEST 12: Mediador reembolsa al comprador
     function testMediadorReembolsaYEvento() public {
         vm.expectEmit(
             false, false, false, true,
             address(fideicomiso)
         );

         emit FondosReembolsados(comprador, 1 ether);

         vm.prank(mediador);
         fideicomiso.resolverDisputaMediador(false);

         assertTrue(fideicomiso.fondosReembolsados());
         assertFalse(fideicomiso.estaCompletado());
         assertEq(comprador.balance, 10 ether);
         assertEq(address(fideicomiso).balance, 0);
     }

     // TEST 13: Mediador aprueba pagar al vendedor
     function testMediadorApruebaVendedor() public {
         vm.expectEmit(
             false, false, false, true,
             address(fideicomiso)
         );

         emit FondosLiberados(vendedor, 1 ether);

         vm.prank(mediador);
         fideicomiso.resolverDisputaMediador(true);

         assertTrue(fideicomiso.estaCompletado());
         assertEq(vendedor.balance, 1 ether);
         assertEq(address(fideicomiso).balance, 0);
     }

     // TEST 14: Intruso no puede resolver disputas
     function testIntrusoNoPuedeResolver() public {
         vm.expectRevert(
             errorTexto(
                 "Error: Solo el mediador puede resolver la disputa."
             )
         );

         vm.prank(intruso);
         fideicomiso.resolverDisputaMediador(false);
     }

     // TEST 15: El mediador no puede resolver dos veces
     function testMediadorNoPuedeResolverDosVeces() public {
         vm.prank(mediador);
         fideicomiso.resolverDisputaMediador(false);

         vm.expectRevert(
             errorTexto(
                 "Error: El fideicomiso ya ha finalizado."
             )
         );

         vm.prank(mediador);
         fideicomiso.resolverDisputaMediador(true);
     }

     // TEST 16: No retirar despues de un reembolso
     function testNoRetirarDespuesDelReembolso() public {
         vm.prank(mediador);
         fideicomiso.resolverDisputaMediador(false);

         vm.warp(
             fideicomiso.fechaLimiteReclamacion() + 1
         );

         vm.expectRevert(
             errorTexto(
                 "Error: El fideicomiso ya ha finalizado."
             )
         );

         vm.prank(vendedor);
         fideicomiso.retirarPorVencimientoVendedor();
     }
 }
