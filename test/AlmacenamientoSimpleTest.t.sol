
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {AlmacenamientoSimple} from "../src/1_AlmacenamientoSimple.sol";

 contract AlmacenamientoSimpleTest is Test {

     AlmacenamientoSimple almacen;

     function setUp() public {
         almacen = new AlmacenamientoSimple();
     }

     function testNombreInicial() public view {
         assertEq(almacen.obtenerNombre(), "");
     }

     function testGuardarNombre() public {
         almacen.establecerNombre("Empresa ABC");

         assertEq(
             almacen.obtenerNombre(),
             "Empresa ABC"
         );
     }

     function testActualizarNombre() public {
         almacen.establecerNombre("Empresa ABC");

         almacen.establecerNombre("Empresa XYZ");

        /* FALLA:
         assertEq(
             almacen.obtenerNombre(),
             "Empresa INCORRECTA"
         );
         */

         // PASA: 
         assertEq(
             almacen.obtenerNombre(),
             "Empresa XYZ"
         );

     }
 }

