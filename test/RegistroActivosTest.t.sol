// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {RegistroActivos} from "../src/2_RegistroActivos.sol";

contract RegistroActivosTest is Test {
    RegistroActivos activos;

    address custodioInicial = address(0x1111111111111111111111111111111111111111);

    address custodioNuevo = address(0x2222222222222222222222222222222222222222);

    function setUp() public {
        activos = new RegistroActivos(101, 15000, custodioInicial);
    }

    function testInicializacion() public view {
        assertEq(activos.idActivo(), 101);
        assertEq(activos.valorUSD(), 15000);
        assertFalse(activos.estaDepreciado());
        assertEq(activos.custodio(), custodioInicial);
    }

    function testDepreciarActivo() public {
        activos.depreciarActivo();

        assertTrue(activos.estaDepreciado());
        assertEq(activos.valorUSD(), 0);
    }

    function testReasignarCustodio() public {
        activos.reasignarCustodio(custodioNuevo);

        assertEq(activos.custodio(), custodioNuevo);
    }

    // vm.prank(desconocido) hace que la siguiente llamada al contrato se ejecute simulando que msg.sender es la dirección desconocido
    function testCualquieraPuedeCambiarCustodio() public {
        address desconocido = address(0x3333333333333333333333333333333333333333);

        vm.prank(desconocido);

        activos.reasignarCustodio(custodioNuevo);

        assertEq(activos.custodio(), custodioNuevo);
    }
}
