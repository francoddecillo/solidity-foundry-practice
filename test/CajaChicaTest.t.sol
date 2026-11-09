// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {CajaChica} from "../src/8_CajaChica.sol";

contract CajaChicaTest is Test {
    CajaChica caja;

    address payable destinatario = payable(address(0xBEEF));

    address intruso = address(0xBAD);

    function setUp() public {
        caja = new CajaChica(1 ether);

        vm.deal(address(this), 10 ether);
    }

    // Funcion auxiliar para depositar ETH
    function depositar(uint256 monto) internal {
        (bool exito,) = payable(address(caja)).call{value: monto}("");

        assertTrue(exito);
    }

    // TEST 1: Estado inicial
    function testEstadoInicial() public view {
        assertEq(caja.administrador(), address(this));
        assertEq(caja.limiteRetiroMaximo(), 1 ether);
        assertEq(caja.obtenerBalance(), 0);
    }

    // TEST 2: Depositar ETH
    function testDepositar() public {
        depositar(2 ether);

        assertEq(caja.obtenerBalance(), 2 ether);
    }

    // TEST 3: Retiro exitoso
    function testRetiroExitoso() public {
        depositar(2 ether);

        caja.retirarFondos(0.5 ether, destinatario);

        assertEq(caja.obtenerBalance(), 1.5 ether);
        assertEq(destinatario.balance, 0.5 ether);
    }

    // TEST 4: Superar limite de retiro
    function testRetiroSuperaLimite() public {
        depositar(2 ether);

        vm.expectRevert(
            abi.encodeWithSignature("Error(string)", "Error: El monto supera el limite de retiro permitido.")
        );

        caja.retirarFondos(1.5 ether, destinatario);
    }

    // TEST 5: Fondos insuficientes
    function testSaldoInsuficiente() public {
        depositar(1.5 ether);

        caja.cambiarLimiteRetiro(3 ether);

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: Fondos insuficientes en la caja chica."));

        caja.retirarFondos(2 ether, destinatario);
    }

    // TEST 6: Destinatario invalido
    function testDestinatarioCero() public {
        depositar(2 ether);

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Error: Direccion de destinatario no valida."));

        caja.retirarFondos(0.5 ether, payable(address(0)));
    }

    // TEST 7: Intruso intenta retirar
    function testIntrusoNoPuedeRetirar() public {
        depositar(2 ether);

        vm.expectRevert(
            abi.encodeWithSignature(
                "Error(string)", "Error: Solo el administrador de la caja chica puede realizar esto."
            )
        );

        vm.prank(intruso);

        caja.retirarFondos(0.5 ether, destinatario);
    }

    // TEST 8: Modificar limite de retiro
    function testCambiarLimite() public {
        caja.cambiarLimiteRetiro(3 ether);

        assertEq(caja.limiteRetiroMaximo(), 3 ether);
    }

    // TEST 9: Intruso intenta modificar limite
    function testIntrusoNoPuedeCambiarLimite() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "Error(string)", "Error: Solo el administrador de la caja chica puede realizar esto."
            )
        );

        vm.prank(intruso);

        caja.cambiarLimiteRetiro(3 ether);
    }
}
