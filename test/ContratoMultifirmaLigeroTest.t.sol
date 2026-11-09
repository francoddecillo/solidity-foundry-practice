// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ContratoMultifirmaLigero} from "../src/14_ContratoMultifirmaLigero.sol";

// Contrato auxiliar que rechaza recibir ETH
contract ReceptorQueRechazaMultifirma {
    receive() external payable {
        revert("No acepto ETH");
    }
}

contract ContratoMultifirmaLigeroTest is Test {
    ContratoMultifirmaLigero multifirma;

    address director1 = address(0xA11CE);
    address director2 = address(0xB0B);
    address director3 = address(0xCAFE);
    address intruso = address(0xBAD);

    address payable beneficiario = payable(address(0xBEEF));

    event PropuestaCreada(uint256 idPropuesta, address destinatario, uint256 monto);

    event PropuestaAprobada(uint256 idPropuesta, address director);

    event TransaccionEjecutada(uint256 idPropuesta, address destinatario, uint256 monto);

    function setUp() public {
        multifirma = new ContratoMultifirmaLigero(director1, director2, director3);

        vm.deal(address(this), 10 ether);

        // Depositar 2 ETH ficticios en la tesoreria
        (bool exito,) = payable(address(multifirma)).call{value: 2 ether}("");

        assertTrue(exito);
    }

    // Funcion auxiliar: crear propuesta de 0.5 ETH
    function crearPropuesta() internal {
        vm.prank(director1);

        multifirma.crearPropuestaRetiro(beneficiario, 0.5 ether);
    }

    // Funcion auxiliar: obtener dos aprobaciones
    function aprobarConDosDirectores() internal {
        vm.prank(director1);
        multifirma.aprobarPropuesta(0);

        vm.prank(director2);
        multifirma.aprobarPropuesta(0);
    }

    // TEST 1: Configuracion inicial
    function testConfiguracionInicial() public view {
        assertEq(multifirma.director1(), director1);
        assertEq(multifirma.director2(), director2);
        assertEq(multifirma.director3(), director3);

        assertEq(multifirma.obtenerTotalPropuestas(), 0);
        assertEq(address(multifirma).balance, 2 ether);
    }

    // TEST 2: No aceptar una direccion cero
    function testConstructorRechazaDireccionCero() public {
        vm.expectRevert("Error: Direcciones invalidas.");

        new ContratoMultifirmaLigero(director1, address(0), director3);
    }

    // TEST 3: Recibir un deposito directo
    function testDepositoDirecto() public {
        (bool exito,) = payable(address(multifirma)).call{value: 1 ether}("");

        assertTrue(exito);
        assertEq(address(multifirma).balance, 3 ether);
    }

    // TEST 4: Crear propuesta y comprobar evento
    function testCrearPropuestaYEvento() public {
        vm.expectEmit(false, false, false, true, address(multifirma));

        emit PropuestaCreada(0, beneficiario, 0.5 ether);

        crearPropuesta();

        assertEq(multifirma.obtenerTotalPropuestas(), 1);

        (address destinatario, uint256 monto, uint256 aprobaciones, bool ejecutada) = multifirma.propuestas(0);

        assertEq(destinatario, beneficiario);
        assertEq(monto, 0.5 ether);
        assertEq(aprobaciones, 0);
        assertFalse(ejecutada);
    }

    // TEST 5: Intruso no puede crear propuestas
    function testIntrusoNoPuedeCrear() public {
        vm.expectRevert("Error: Acceso denegado. Solo los directores autorizados pueden llamar a esta funcion.");

        vm.prank(intruso);

        multifirma.crearPropuestaRetiro(beneficiario, 0.5 ether);
    }

    // TEST 6: No aceptar destinatario cero
    function testDestinatarioCero() public {
        vm.expectRevert("Error: Destinatario invalido.");

        vm.prank(director1);

        multifirma.crearPropuestaRetiro(payable(address(0)), 0.5 ether);
    }

    // TEST 7: No proponer mas dinero del disponible
    function testMontoSuperaSaldo() public {
        vm.expectRevert("Error: El monto de la propuesta supera el saldo disponible.");

        vm.prank(director1);

        multifirma.crearPropuestaRetiro(beneficiario, 3 ether);
    }

    // TEST 8: Aprobar y comprobar evento
    function testAprobarYEvento() public {
        crearPropuesta();

        vm.expectEmit(false, false, false, true, address(multifirma));

        emit PropuestaAprobada(0, director1);

        vm.prank(director1);
        multifirma.aprobarPropuesta(0);

        assertTrue(multifirma.aprobacionesPorPropuesta(0, director1));

        (,, uint256 aprobaciones,) = multifirma.propuestas(0);

        assertEq(aprobaciones, 1);
    }

    // TEST 9: No aprobar dos veces
    function testNoAprobarDosVeces() public {
        crearPropuesta();

        vm.prank(director1);
        multifirma.aprobarPropuesta(0);

        vm.expectRevert("Error: Ya has aprobado esta propuesta previamente.");

        vm.prank(director1);
        multifirma.aprobarPropuesta(0);
    }

    // TEST 10: Intruso no puede aprobar
    function testIntrusoNoPuedeAprobar() public {
        crearPropuesta();

        vm.expectRevert("Error: Acceso denegado. Solo los directores autorizados pueden llamar a esta funcion.");

        vm.prank(intruso);
        multifirma.aprobarPropuesta(0);
    }

    // TEST 11: Una aprobacion no alcanza
    function testUnaAprobacionNoAlcanza() public {
        crearPropuesta();

        vm.prank(director1);
        multifirma.aprobarPropuesta(0);

        vm.expectRevert("Error: La propuesta requiere al menos 2 aprobaciones para ejecutarse.");

        vm.prank(director3);
        multifirma.ejecutarRetiro(0);
    }

    // TEST 12: Dos aprobaciones permiten ejecutar
    function testEjecutarConDosAprobacionesYEvento() public {
        crearPropuesta();
        aprobarConDosDirectores();

        vm.expectEmit(false, false, false, true, address(multifirma));

        emit TransaccionEjecutada(0, beneficiario, 0.5 ether);

        // Director 3 ejecuta sin haber aprobado
        vm.prank(director3);
        multifirma.ejecutarRetiro(0);

        assertEq(beneficiario.balance, 0.5 ether);
        assertEq(address(multifirma).balance, 1.5 ether);

        (,, uint256 aprobaciones, bool ejecutada) = multifirma.propuestas(0);

        assertEq(aprobaciones, 2);
        assertTrue(ejecutada);
    }

    // TEST 13: No ejecutar dos veces
    function testNoEjecutarDosVeces() public {
        crearPropuesta();
        aprobarConDosDirectores();

        vm.prank(director3);
        multifirma.ejecutarRetiro(0);

        vm.expectRevert("Error: La propuesta ya fue ejecutada.");

        vm.prank(director3);
        multifirma.ejecutarRetiro(0);
    }

    // TEST 14: No aprobar una propuesta ejecutada
    function testNoAprobarPropuestaEjecutada() public {
        crearPropuesta();
        aprobarConDosDirectores();

        vm.prank(director3);
        multifirma.ejecutarRetiro(0);

        vm.expectRevert("Error: La propuesta ya fue ejecutada.");

        vm.prank(director3);
        multifirma.aprobarPropuesta(0);
    }

    // TEST 15: Las aprobaciones son independientes
    function testAprobacionesIndependientes() public {
        vm.startPrank(director1);

        multifirma.crearPropuestaRetiro(beneficiario, 0.5 ether);

        multifirma.crearPropuestaRetiro(beneficiario, 0.7 ether);

        multifirma.aprobarPropuesta(0);
        multifirma.aprobarPropuesta(1);

        vm.stopPrank();

        assertTrue(multifirma.aprobacionesPorPropuesta(0, director1));

        assertTrue(multifirma.aprobacionesPorPropuesta(1, director1));

        (,, uint256 aprobaciones0,) = multifirma.propuestas(0);

        (,, uint256 aprobaciones1,) = multifirma.propuestas(1);

        assertEq(aprobaciones0, 1);
        assertEq(aprobaciones1, 1);
    }

    // TEST 16: El saldo puede cambiar antes de ejecutar
    function testSaldoInsuficienteAlEjecutar() public {
        vm.startPrank(director1);

        multifirma.crearPropuestaRetiro(beneficiario, 2 ether);

        multifirma.crearPropuestaRetiro(beneficiario, 1 ether);

        multifirma.aprobarPropuesta(0);
        multifirma.aprobarPropuesta(1);

        vm.stopPrank();

        vm.startPrank(director2);

        multifirma.aprobarPropuesta(0);
        multifirma.aprobarPropuesta(1);

        vm.stopPrank();

        // Ejecutamos primero la propuesta 1
        vm.prank(director3);
        multifirma.ejecutarRetiro(1);

        assertEq(address(multifirma).balance, 1 ether);

        // Ya no quedan los 2 ETH que requiere la 0
        vm.expectRevert("Error: Saldo insuficiente en el contrato para transferir.");

        vm.prank(director3);
        multifirma.ejecutarRetiro(0);
    }

    // TEST 17: No aprobar un ID inexistente
    function testPropuestaInexistente() public {
        vm.expectRevert("Error: La propuesta no existe.");

        vm.prank(director1);
        multifirma.aprobarPropuesta(999);
    }

    // TEST 18: Intruso no puede ejecutar
    function testIntrusoNoPuedeEjecutar() public {
        crearPropuesta();
        aprobarConDosDirectores();

        vm.expectRevert("Error: Acceso denegado. Solo los directores autorizados pueden llamar a esta funcion.");

        vm.prank(intruso);
        multifirma.ejecutarRetiro(0);
    }

    // TEST 19: Una transferencia fallida revierte todo
    function testTransferenciaFallidaRevierteTodo() public {
        ReceptorQueRechazaMultifirma receptor = new ReceptorQueRechazaMultifirma();

        vm.prank(director1);

        multifirma.crearPropuestaRetiro(payable(address(receptor)), 0.5 ether);

        aprobarConDosDirectores();

        vm.expectRevert("Error: La transferencia fallo.");

        vm.prank(director3);
        multifirma.ejecutarRetiro(0);

        (,,, bool ejecutada) = multifirma.propuestas(0);

        assertFalse(ejecutada);

        assertEq(address(multifirma).balance, 2 ether);
    }

    // TEST 20: El contrato permite monto cero
    function testMontoCeroPermitido() public {
        vm.prank(director1);

        multifirma.crearPropuestaRetiro(beneficiario, 0);

        aprobarConDosDirectores();

        vm.prank(director3);
        multifirma.ejecutarRetiro(0);

        (, uint256 monto,, bool ejecutada) = multifirma.propuestas(0);

        assertEq(monto, 0);
        assertTrue(ejecutada);
        assertEq(beneficiario.balance, 0);

        // No se transfirieron fondos
        assertEq(address(multifirma).balance, 2 ether);
    }
}
