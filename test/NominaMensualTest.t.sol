// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NominaMensual} from "../src/9_NominaMensual.sol";

contract NominaMensualTest is Test {
    NominaMensual nomina;

    address payable empleado = payable(address(0x1111));
    address intruso = address(0x2222);

    // Los eventos deben coincidir con los del contrato
    event FondosRecibidos(address indexed remitente, uint256 monto);

    event SalarioPagado(address indexed empleado, uint256 monto, uint256 fecha);

    function setUp() public {
        nomina = new NominaMensual();
        vm.deal(address(this), 10 ether);
    }

    // TEST 1: Tesorero inicial
    function testTesoreroInicial() public view {
        assertEq(nomina.tesorero(), address(this));
    }

    // TEST 2: Deposito y evento
    function testDepositarFondosYEvento() public {
        vm.expectEmit(true, false, false, true, address(nomina));

        emit FondosRecibidos(address(this), 2 ether);

        nomina.depositarFondos{value: 2 ether}();

        assertEq(nomina.obtenerFondosDisponibles(), 2 ether);
    }

    // TEST 3: Deposito de cero ETH
    function testDepositoCero() public {
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: Debe depositar un monto mayor a cero."));

        nomina.depositarFondos{value: 0}();
    }

    // TEST 4: Intruso intenta depositar
    function testIntrusoNoPuedeDepositar() public {
        vm.deal(intruso, 1 ether);
        vm.prank(intruso);

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: Solo el Tesorero puede realizar pagos."));

        nomina.depositarFondos{value: 1 ether}();
    }

    // TEST 5: Pago exitoso y evento
    function testPagoSalarioYEvento() public {
        nomina.depositarFondos{value: 2 ether}();

        vm.expectEmit(true, false, false, true, address(nomina));

        emit SalarioPagado(empleado, 0.5 ether, block.timestamp);

        nomina.pagarSalario(empleado, 0.5 ether);

        assertEq(empleado.balance, 0.5 ether);

        assertEq(nomina.obtenerFondosDisponibles(), 1.5 ether);
    }

    // TEST 6: Fondos insuficientes
    function testFondosInsuficientes() public {
        nomina.depositarFondos{value: 2 ether}();

        vm.expectRevert(
            abi.encodeWithSignature("Error(string)", "Error: Fondos insuficientes en el contrato de nomina.")
        );

        nomina.pagarSalario(empleado, 3 ether);
    }

    // TEST 7: Empleado con direccion cero
    function testEmpleadoCero() public {
        nomina.depositarFondos{value: 2 ether}();

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: Direccion de empleado no valida."));

        nomina.pagarSalario(payable(address(0)), 0.5 ether);
    }

    // TEST 8: Intruso intenta pagar
    function testIntrusoNoPuedePagar() public {
        nomina.depositarFondos{value: 2 ether}();

        vm.prank(intruso);

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: Solo el Tesorero puede realizar pagos."));

        nomina.pagarSalario(empleado, 0.5 ether);
    }

    // TEST 9: El contrato permite pagar cero
    function testSalarioCeroPermitido() public {
        nomina.pagarSalario(empleado, 0);

        assertEq(empleado.balance, 0);
    }
}
