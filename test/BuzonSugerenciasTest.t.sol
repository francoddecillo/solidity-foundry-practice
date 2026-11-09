// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {BuzonSugerencias} from "../src/7_BuzonSugerencias.sol";

contract BuzonSugerenciasTest is Test {
    BuzonSugerencias buzon;

    address empleado = address(0x1111);
    address intruso = address(0x2222);

    function setUp() public {
        buzon = new BuzonSugerencias();
    }

    // TEST 1: Estado inicial
    function testEstadoInicial() public view {
        assertEq(buzon.obtenerTotalSugerencias(), 0);
        assertEq(buzon.contarSugerenciasProcesadas(), 0);
        assertEq(buzon.encargadoRRHH(), address(this));
    }

    // TEST 2: Crear una sugerencia
    function testCrearSugerencia() public {
        vm.prank(empleado);
        buzon.crearSugerencia("Mejorar oficinas");

        (address autor, string memory descripcion, uint256 votos, bool procesada) = buzon.sugerencias(0);

        assertEq(autor, empleado);
        assertEq(descripcion, "Mejorar oficinas");
        assertEq(votos, 0);
        assertFalse(procesada);
    }

    // TEST 3: Rechazar sugerencia vacia
    function testSugerenciaVacia() public {
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: La sugerencia no puede estar vacia."));

        buzon.crearSugerencia("");
    }

    // TEST 4: Multiples sugerencias
    function testMultiplesSugerencias() public {
        buzon.crearSugerencia("Idea A");
        buzon.crearSugerencia("Idea B");
        buzon.crearSugerencia("Idea C");

        assertEq(buzon.obtenerTotalSugerencias(), 3);

        (, string memory descripcion,,) = buzon.sugerencias(2);

        assertEq(descripcion, "Idea C");
    }

    // TEST 5: Votos duplicados
    function testVotosDuplicados() public {
        buzon.crearSugerencia("Nueva capacitacion");

        // Mantiene el remitente simulado durante varias llamadas:
        vm.startPrank(empleado);

        buzon.apoyarSugerencia(0);
        buzon.apoyarSugerencia(0);

        // Finaliza esa simulación:
        vm.stopPrank();

        (,, uint256 votos,) = buzon.sugerencias(0);

        assertEq(votos, 2);
    }

    // TEST 6: Votar sugerencia inexistente
    function testSugerenciaInexistente() public {
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: La sugerencia no existe."));

        buzon.apoyarSugerencia(99);
    }

    // TEST 7: Solo RRHH puede procesar
    function testIntrusoNoPuedeProcesar() public {
        buzon.crearSugerencia("Mejorar equipos");

        vm.expectRevert(
            abi.encodeWithSignature("Error(string)", "Error: Solo el encargado de RRHH puede realizar esta accion.")
        );

        vm.prank(intruso);
        buzon.procesarSugerencia(0);
    }

    // TEST 8: Contar sugerencias procesadas
    function testContarProcesadas() public {
        buzon.crearSugerencia("Idea A");
        buzon.crearSugerencia("Idea B");
        buzon.crearSugerencia("Idea C");

        buzon.procesarSugerencia(0);
        buzon.procesarSugerencia(2);

        assertEq(buzon.contarSugerenciasProcesadas(), 2);
    }
}
