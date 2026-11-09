// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ListaProveedoresCompletos} from "../src/6_ListaProveedoresCompletos.sol";

contract ListaProveedoresCompletosTest is Test {
    ListaProveedoresCompletos lista;

    address proveedorA = address(0x1111);
    address proveedorB = address(0x2222);
    address intruso = address(0x3333);

    function setUp() public {
        lista = new ListaProveedoresCompletos();
    }

    // TEST 1: El gerente inicial
    function testGerenteInicial() public view {
        assertEq(lista.gerenteFinanzas(), address(this));
    }

    // TEST 2: Registrar dos proveedores
    function testRegistrarDosProveedores() public {
        lista.registrarProveedor(proveedorA, "Proveedor A", "11111111");

        lista.registrarProveedor(proveedorB, "Proveedor B", "22222222");

        (string memory nombreA,,, bool activoA) = lista.proveedores(proveedorA);

        (string memory nombreB,,, bool activoB) = lista.proveedores(proveedorB);

        assertEq(nombreA, "Proveedor A");
        assertEq(nombreB, "Proveedor B");
        assertTrue(activoA);
        assertTrue(activoB);
    }

    // TEST 3: Compras independientes
    function testComprasIndependientes() public {
        lista.registrarProveedor(proveedorA, "Proveedor A", "11111111");

        lista.registrarProveedor(proveedorB, "Proveedor B", "22222222");

        lista.registrarCompra(proveedorA, 1200);
        lista.registrarCompra(proveedorA, 300);
        lista.registrarCompra(proveedorB, 750);

        (,, uint256 volumenA,) = lista.proveedores(proveedorA);
        (,, uint256 volumenB,) = lista.proveedores(proveedorB);

        assertEq(volumenA, 1500);
        assertEq(volumenB, 750);
    }

    // TEST 4: Proveedor inactivo
    function testProveedorInactivo() public {
        lista.registrarProveedor(proveedorA, "Proveedor A", "11111111");

        lista.establecerEstadoProveedor(proveedorA, false);

        vm.expectRevert(
            abi.encodeWithSignature("Error(string)", "Error: El proveedor no esta registrado o esta inactivo.")
        );

        lista.registrarCompra(proveedorA, 500);
    }

    // TEST 5: Reactivar proveedor
    function testReactivarProveedor() public {
        lista.registrarProveedor(proveedorA, "Proveedor A", "11111111");

        lista.establecerEstadoProveedor(proveedorA, false);
        lista.establecerEstadoProveedor(proveedorA, true);
        lista.registrarCompra(proveedorA, 500);

        (,, uint256 volumen, bool activo) = lista.proveedores(proveedorA);

        assertEq(volumen, 500);
        assertTrue(activo);
    }

    // TEST 6: Intruso sin permisos
    function testIntrusoNoPuedeRegistrar() public {
        vm.prank(intruso);

        vm.expectRevert(
            abi.encodeWithSignature("Error(string)", "Error: Solo el Gerente de Finanzas puede realizar esto.")
        );

        lista.registrarProveedor(proveedorA, "Falso", "99999999");
    }

    // TEST 7: Re-registro reinicia compras
    function testReRegistroReiniciaCompras() public {
        lista.registrarProveedor(proveedorA, "Proveedor A", "11111111");

        lista.registrarCompra(proveedorA, 2000);

        lista.registrarProveedor(proveedorA, "Proveedor A Nuevo", "11111111");

        (,, uint256 volumen, bool activo) = lista.proveedores(proveedorA);

        assertEq(volumen, 0);
        assertTrue(activo);
    }

    // TEST 8: Activar proveedor inexistente
    function testActivarProveedorInexistente() public {
        address desconocido = address(0x4444);

        lista.establecerEstadoProveedor(desconocido, true);

        lista.registrarCompra(desconocido, 500);

        (string memory nombre,, uint256 volumen, bool activo) = lista.proveedores(desconocido);

        assertEq(nombre, "");
        assertEq(volumen, 500);
        assertTrue(activo);
    }
}
