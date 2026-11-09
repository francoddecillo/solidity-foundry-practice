
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {VotacionDirectorio} from "../src/13_VotacionDirectorio.sol";

 contract VotacionDirectorioTest is Test {

     VotacionDirectorio votacion;

     address director1 = address(0xA11CE);
     address director2 = address(0xB0B);
     address director3 = address(0xCAFE);
     address intruso = address(0xBAD);

     event PropuestaCreada(
         string descripcion,
         uint256 limiteTiempo
     );

     event VotoEmitido(
         address director,
         bool aFavor
     );

     event VotacionCerrada(
         uint256 votosAFavor,
         uint256 votosEnContra,
         bool aprobada
     );

     function setUp() public {
         vm.warp(1_000_000);

         address[] memory directores = new address[](3);

         directores[0] = director1;
         directores[1] = director2;
         directores[2] = director3;

         votacion = new VotacionDirectorio(directores);
     }

     function iniciar() internal {
         votacion.iniciarVotacion(
             "Comprar equipamiento",
             1 days
         );
     }

     function fechaLimite()
         internal
         view
         returns (uint256 limite)
     {
         (, , , limite, ) = votacion.propuestaActual();
     }

     function conteos()
         internal
         view
         returns (uint256 favor, uint256 contra)
     {
         (, favor, contra, , ) = votacion.propuestaActual();
     }

     // TEST 1: Secretario y directores iniciales
     function testConfiguracionInicial() public view {
         assertEq(
             votacion.secretarioGeneral(),
             address(this)
         );

         assertTrue(votacion.esDirector(director1));
         assertTrue(votacion.esDirector(director2));
         assertTrue(votacion.esDirector(director3));
         assertFalse(votacion.esDirector(intruso));
     }

     // TEST 2: Crear propuesta y comprobar evento
     function testCrearPropuestaYEvento() public {
         vm.expectEmit(
             false, false, false, true,
             address(votacion)
         );

         emit PropuestaCreada(
             "Comprar equipamiento",
             block.timestamp + 1 days
         );

         iniciar();

         (
             string memory descripcion,
             uint256 favor,
             uint256 contra,
             uint256 limite,
             bool ejecutada
         ) = votacion.propuestaActual();

         assertEq(descripcion, "Comprar equipamiento");
         assertEq(favor, 0);
         assertEq(contra, 0);
         assertEq(limite, block.timestamp + 1 days);
         assertFalse(ejecutada);
     }

     // TEST 3: No permitir descripcion vacia
     function testDescripcionVacia() public {
         vm.expectRevert(
             "Error: La descripcion no puede estar vacia."
         );

         votacion.iniciarVotacion("", 1 days);
     }

     // TEST 4: Un intruso no puede crear propuestas
     function testIntrusoNoPuedeCrearPropuesta() public {
         vm.expectRevert(
             "Error: Solo el secretario puede administrar la votacion."
         );

         vm.prank(intruso);
         votacion.iniciarVotacion("Nueva propuesta", 1 days);
     }

     // TEST 5: Voto a favor y evento
     function testVotoAFavorYEvento() public {
         iniciar();

         vm.expectEmit(
             false, false, false, true,
             address(votacion)
         );

         emit VotoEmitido(director1, true);

         vm.prank(director1);
         votacion.votar(true);

         assertTrue(votacion.haVotado(director1));

         (uint256 favor, uint256 contra) = conteos();

         assertEq(favor, 1);
         assertEq(contra, 0);
     }

     // TEST 6: Conteo de tres directores
     function testConteoTresVotos() public {
         iniciar();

         vm.prank(director1);
         votacion.votar(true);

         vm.prank(director2);
         votacion.votar(true);

         vm.prank(director3);
         votacion.votar(false);

         (uint256 favor, uint256 contra) = conteos();

         assertEq(favor, 2);
         assertEq(contra, 1);
     }

     // TEST 7: Impedir doble voto
     function testNoVotarDosVeces() public {
         iniciar();

         vm.prank(director1);
         votacion.votar(true);

         vm.expectRevert(
             "Error: Ya has emitido tu voto para esta propuesta."
         );

         vm.prank(director1);
         votacion.votar(false);

         (uint256 favor, uint256 contra) = conteos();

         assertEq(favor, 1);
         assertEq(contra, 0);
     }

     // TEST 8: No puede votar un usuario externo
     function testIntrusoNoPuedeVotar() public {
         iniciar();

         vm.expectRevert(
             "Error: Acceso denegado. Solo los directores autorizados pueden votar."
         );

         vm.prank(intruso);
         votacion.votar(true);
     }

     // TEST 9: No cerrar antes del plazo
     function testNoCerrarAntesDelPlazo() public {
         iniciar();

         vm.expectRevert(
             "Error: El periodo de votacion aun esta activo."
         );

         votacion.cerrarVotacion();
     }

     // TEST 10: Se puede votar exactamente al vencer
     function testVotarEnFechaLimite() public {
         iniciar();

         vm.warp(fechaLimite());

         vm.prank(director1);
         votacion.votar(true);

         (uint256 favor, ) = conteos();

         assertEq(favor, 1);
     }

     // TEST 11: No se puede cerrar exactamente al vencer
     function testNoCerrarEnFechaLimite() public {
         iniciar();

         vm.warp(fechaLimite());

         vm.expectRevert(
             "Error: El periodo de votacion aun esta activo."
         );

         votacion.cerrarVotacion();
     }

     // TEST 12: No votar despues del vencimiento
     function testNoVotarDespuesDelPlazo() public {
         iniciar();

         vm.warp(fechaLimite() + 1);

         vm.expectRevert(
             "Error: El periodo de votacion ha expirado."
         );

         vm.prank(director1);
         votacion.votar(true);
     }

     // TEST 13: Cierre aprobado y evento
     function testCerrarAprobadaYEvento() public {
         iniciar();

         vm.prank(director1);
         votacion.votar(true);

         vm.prank(director2);
         votacion.votar(true);

         vm.prank(director3);
         votacion.votar(false);

         vm.warp(fechaLimite() + 1);

         vm.expectEmit(
             false, false, false, true,
             address(votacion)
         );

         emit VotacionCerrada(2, 1, true);

         bool aprobada = votacion.cerrarVotacion();

         assertTrue(aprobada);

         (, , , , bool ejecutada) =
             votacion.propuestaActual();

         assertTrue(ejecutada);
     }

     // TEST 14: Un empate no aprueba la propuesta
     function testEmpateNoAprueba() public {
         iniciar();

         vm.prank(director1);
         votacion.votar(true);

         vm.prank(director2);
         votacion.votar(false);

         vm.warp(fechaLimite() + 1);

         bool aprobada = votacion.cerrarVotacion();

         assertFalse(aprobada);
     }

     // TEST 15: No cerrar dos veces
     function testNoCerrarDosVeces() public {
         iniciar();

         vm.warp(fechaLimite() + 1);

         votacion.cerrarVotacion();

         vm.expectRevert(
             "Error: La votacion ya ha sido ejecutada/cerrada."
         );

         votacion.cerrarVotacion();
     }

     // TEST 16: Intruso no puede cerrar
     function testIntrusoNoPuedeCerrar() public {
         iniciar();

         vm.warp(fechaLimite() + 1);

         vm.expectRevert(
             "Error: Solo el secretario puede administrar la votacion."
         );

         vm.prank(intruso);
         votacion.cerrarVotacion();
     }

     // TEST 17: Demostracion del problema haVotado
     function testBugVotoBloqueadoEnNuevaPropuesta() public {
         iniciar();

         vm.prank(director1);
         votacion.votar(true);

         vm.warp(fechaLimite() + 1);

         votacion.cerrarVotacion();

         votacion.iniciarVotacion(
             "Abrir nueva sucursal",
             1 days
         );

         // El registro anterior sigue siendo true
         assertTrue(votacion.haVotado(director1));

         vm.expectRevert(
             "Error: Ya has emitido tu voto para esta propuesta."
         );

         vm.prank(director1);
         votacion.votar(true);
     }

     // TEST 18: Demostracion de reemplazo de propuesta activa
     function testBugReemplazarPropuestaActiva() public {
         iniciar();

         vm.prank(director1);
         votacion.votar(true);

         // El secretario reemplaza una votacion abierta
         votacion.iniciarVotacion(
             "Otra inversion",
             1 days
         );

         (
             string memory descripcion,
             uint256 favor,
             uint256 contra,
             ,
             bool ejecutada
         ) = votacion.propuestaActual();

         assertEq(descripcion, "Otra inversion");
         assertEq(favor, 0);
         assertEq(contra, 0);
         assertFalse(ejecutada);

         // El voto previo no se reinicio en el mapping
         assertTrue(votacion.haVotado(director1));
     }
 }
