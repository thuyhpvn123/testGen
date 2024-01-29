pragma solidity 0.8.19;
import "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
import {KVenture} from "../src/kventure/kventure.sol";
import {MasterPool} from "../src/kventure/MasterPool.sol";
import {USDT} from "../src/kventure/USDT.sol";
import {BinaryTree} from "../src/kventure/BinaryTree.sol";
import {KventureCode} from "../src/kventure/GenerateCode.sol";
import {Product} from "../src/kventure/Product.sol";
import {KventureNft} from "../src/kventure/PackageNFT.sol";
import {PackageInfoStruct} from "../src/kventure/AbstractPackage.sol";
contract KventureTest is Test{
    KVenture public kventure;
    MasterPool public masterPool;
    KventureCode public kVentureCode;
    USDT public usdt;
    BinaryTree public binarytree;
    Product public product;
    KventureNft public nft;
    address public deployer = address(0x123456);
    address public root = address(0x1);
    address public wallet = address(0x12345678);
    address public partnerWallet = address(0x123456789);
    address public mtn = address(0x12345);
    bytes32 public codeRoot;
    address public minter = address(0x123);
    address public boostStorage = address(0x124);

    //branch 1
    address [] public level1;
    bytes32 [] refcodeLevel1;
    address [] public level2;
    bytes32 [] refcodeLevel2;
    address [] public level3;
    bytes32 [] refcodeLevel3;
    bytes32 phone= bytes32(0x40948b0de70ef650857db7858448d3981a2be2d06b40551427eefe1b1f956f31);
    bytes32 [] refcode;
    address [] public addressList;
    uint256 USDT_AMOUNT = 1_000_000;
    bytes32 code0xb6;
    //3-6-16
    // constructor(){
    //     initAddressList();
    // }
    function setUp()public{
        vm.startPrank(deployer);
        kventure = new KVenture();
        usdt = new USDT();
        masterPool = new MasterPool(address(usdt));
        binarytree = new BinaryTree();
        kVentureCode = new KventureCode();
        nft = new KventureNft();
        product = new Product();
        kventure.initialize(address(usdt),address(masterPool),address(binarytree),root,wallet,partnerWallet,address(kVentureCode),address(mtn));
        kventure.SetPackageController(address(product));
        masterPool.setController(address(kventure));        
        masterPool.setController(address(product));
        kVentureCode.initialize(address(usdt),address(masterPool),address(minter),address(boostStorage),address(product),address(nft),address(kventure));
        bytes32  MINTER_ROLE = keccak256("MINTER_ROLE");
        nft.grantRole(MINTER_ROLE,address(kVentureCode));
        product.initialize(address(usdt),address(masterPool),address(kVentureCode),address(kventure));
        product.SetAdmin(deployer);
        initAddressList();
        vm.stopPrank();
        getRefCodeRoot();
        vm.stopPrank();
        addressList = [address(0x1),address(0x2),address(0x3),address(0x4),address(0x5),address(0x6),address(0x7),address(0x8),address(0x9),address(0x10),address(0x11),address(0x12),address(0x13),address(0xb1),address(0xb2),address(0xb3),address(0xb4),address(0xb5),address(0xb6),address(0xb7),address(0xb8),address(0xb9),address(0xb10),address(0xb11),address(0xb12)];
        Register();
    }
    function initAddressList() internal {
        usdt.mintToAddress(address(0x2), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x3), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x4), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x5), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x6), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x7), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x8), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x9), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x10), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x11), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x12), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0x13), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb1), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb2), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb3), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb4), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb5), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb6), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb7), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb8), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb9), 160*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb10), 160*USDT_AMOUNT);
    //     usdt.mintToAddress(address(0xb11), 160*USDT_AMOUNT);
    //     usdt.mintToAddress(address(0xb12), 160*USDT_AMOUNT);
    }

    function getRefCodeRoot() internal {
        vm.startPrank(root);
        codeRoot = kventure.GetCodeRef();
        vm.stopPrank();
    }

    function setRank() internal {
        vm.startPrank(root);
        kventure.UpdateRank(root,5);
        // kventure.UpdateRank(address(0x3),2);
        vm.stopPrank();
    }
    function Register()public{
        //b11 register
        vm.startPrank(address(0x2));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(codeRoot,codeRoot,11,bytes32("0x2"),address(0x2));
        bytes32 code0x2 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0x3));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(codeRoot,codeRoot,11,bytes32("0x3"),address(0x3));
        bytes32 code0x3 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0x4));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(codeRoot,codeRoot,11,bytes32("0x4"),address(0x4));
        bytes32 code0x4 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0x5));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(codeRoot,codeRoot,11,bytes32("0x5"),address(0x5));
        bytes32 code0x5 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0x6));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x2,code0x2,11,bytes32("0x6"),address(0x6));
        vm.stopPrank();

        vm.startPrank(address(0x7));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x2,code0x2,11,bytes32("0x7"),address(0x7));
        vm.stopPrank();

        vm.startPrank(address(0x8));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x3,code0x3,11,bytes32("0x8"),address(0x8));
        bytes32 code0x8 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0x9));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x3,code0x3,11,bytes32("0x9"),address(0x9));
        bytes32 code0x9 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0x10));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x4,code0x4,11,bytes32("0x10"),address(0x10));
        vm.stopPrank();
        
        vm.startPrank(address(0x11));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x4,code0x4,11,bytes32("0x11"),address(0x11));
        vm.stopPrank();

        vm.startPrank(address(0x12));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x5,code0x5,11,bytes32("0x12"),address(0x12));
        bytes32 code0x12 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0x13));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x5,code0x5,11,bytes32("0x13"),address(0x13));
        bytes32 code0x13 = kventure.GetCodeRef();

        vm.startPrank(address(0xb1));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x9,code0x9,11,bytes32("0xb1"),address(0xb1));
        bytes32 code0xb1 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0xb2));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0xb1,code0xb1,11,bytes32("0xb2"),address(0xb2));
        bytes32 code0xb2 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0xb3));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0xb2,code0xb2,11,bytes32("0xb3"),address(0xb3));
        bytes32 code0xb3 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0xb4));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x8,code0x8,11,bytes32("0xb4"),address(0xb4));
        bytes32 code0xb4 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0xb5));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0xb4,code0xb4,11,bytes32("0xb5"),address(0xb5));
        bytes32 code0xb5 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0xb6));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0xb5,code0xb5,11,bytes32("0xb6"),address(0xb6));
        code0xb6 = kventure.GetCodeRef();

        vm.startPrank(address(0xb7));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x12,code0x12,11,bytes32("0xb7"),address(0xb7));
        bytes32 code0xb7 = kventure.GetCodeRef();
        vm.stopPrank();

        vm.startPrank(address(0xb8));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0x13,code0x13,11,bytes32("0xb8"),address(0xb8));
        vm.stopPrank();

        vm.startPrank(address(0xb9));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0xb7,code0xb7,11,bytes32("0xb9"),address(0xb9));
        vm.stopPrank();

        vm.startPrank(address(0xb10));
        usdt.approve(address(kventure),160*USDT_AMOUNT);
        kventure.Register(code0xb3,code0xb3,11,bytes32("0xb10"),address(0xb10));
        vm.stopPrank();

    }
    function testPayBonus()public{
        //admin add product
        vm.startPrank(deployer);
        product.adminAddProduct("a",100_000*USDT_AMOUNT,122_008*USDT_AMOUNT,"ao",true);
        usdt.mintToAddress(address(0xb12), 100_050*USDT_AMOUNT);
        usdt.mintToAddress(address(0xb11), 50*USDT_AMOUNT);
        // usdt.mintToAddress(address(masterPool), 500000000000000000*USDT_AMOUNT);
        PackageInfoStruct.Product [] memory ProductArr = new PackageInfoStruct.Product[](1);
        ProductArr = product.adminViewProduct();

        vm.stopPrank();
                //b11 register
        uint256 fee = 50*USDT_AMOUNT;
        vm.startPrank(address(0xb11));
        usdt.approve(address(kventure),fee);
        kventure.Register(phone,code0xb6,0,bytes32(0),address(0xb11));
        bytes32 code0xb11 = kventure.GetCodeRef();
        vm.stopPrank();
        assertEq(
            usdt.balanceOf(address(0xb11)),
            0,
            "Error balance "
        );
            //b12 register
        vm.startPrank(address(0xb12));
        usdt.approve(address(kventure),fee);
        kventure.Register(phone,code0xb11,0,code0xb11,address(0xb12));
        // bytes32 code0xb12 = kventure.GetCodeRef();
        vm.stopPrank();
        assertEq(
            usdt.balanceOf(address(0xb12)),
            100_000*USDT_AMOUNT,
            "Error balance "
        );
        assertEq(
            usdt.balanceOf(address(0xb11)),
            30*USDT_AMOUNT,
            "Error balance "
        ); 

        // address parent = kventure.GetUserInfo(address(0xb12)).Line;
        // assertEq(
        //     parent,
        //     address(0xb11),
        //     "Error  "
        // ); 

        //address 0xb12 order product
        vm.startPrank(address(0xb12));
        usdt.approve(address(product),100_000*USDT_AMOUNT);

        bytes32[] memory idArr = new bytes32[](1);
        idArr[0] = ProductArr[0].id;
        uint256[] memory quaArr = new uint256[](1);
        quaArr[0]=1;
        bool[] memory lockArr = new bool[](1);
        lockArr[0]=false;
        bytes32[] memory codeHash = new bytes32[](1);
        codeHash[0] = bytes32("234");
        bytes32[][] memory codeHashes = new bytes32[][](1);
        codeHashes[0] = codeHash;
        bool[] memory cloudMinings = new bool[](1);
        cloudMinings[0]=false;
        address[] memory delegates = new address[](1);
        delegates[0]=address(0);
        console.log("balance 0xb11:",usdt.balanceOf(address(0xb11)));

        kventure.UpdateRank(root,5); //set rank de root du dk rank nhan sale bonus
        kventure.UpdateRank(address(0x8),3); //set rank de 0x8 du dk rank nhan sale bonus
        product.order(idArr,quaArr,lockArr,codeHashes,cloudMinings,delegates,code0xb11,address(0xb12));
        vm.stopPrank();      
        assertEq(
            usdt.balanceOf(address(0xb12)),
            0,
            "Error balance "
        ); 
        console.log("linematrix:",usdt.balanceOf(address(0xb11)));

        //test sale bonus
        assertEq(
            kventure.GetUserInfo(address(0xb11)).totalSaleBonus, //(122_008-100_000)*50%
            11_004*USDT_AMOUNT,
            "Error balance "
        ); 

        assertEq(
            kventure.GetUserInfo(address(0x8)).totalSaleBonus, //(122_008-100_000)*2%
            440160000,
            "Error balance "
        ); 
        
        assertEq(
            kventure.GetUserInfo(root).totalSaleBonus, //(122_008-100_000)*1%
            2200800000,
            "Error balance "
        ); 

        // //test payGoodSaleBonusWeekly
        // vm.startPrank(deployer);
        // kventure.payGoodSaleBonusWeekly();  
        // vm.stopPrank();
        // assertEq(
        //     kventure.totalGoodSaleBonus(address(0xb11)),  //(122_008-100_000)*50%
        //     11_004*USDT_AMOUNT,
        //     "Error balance "
        // );

        
    }
    // function testPayBonus()public{
    //     //admin add product
    //     vm.startPrank(deployer);
    //     product.adminAddProduct("a",5000*USDT_AMOUNT,6108*USDT_AMOUNT,"ao",true);
    //     usdt.mintToAddress(address(0xb12), 10000*USDT_AMOUNT);
    //     usdt.mintToAddress(address(0xb11), 50*USDT_AMOUNT);
    //     usdt.mintToAddress(address(masterPool), 500000000000000000*USDT_AMOUNT);
    //     PackageInfoStruct.Product [] memory ProductArr = new PackageInfoStruct.Product[](1);
    //     ProductArr = product.adminViewProduct();

    //     vm.stopPrank();
    //             //b11 register
    //     uint256 fee = 50*USDT_AMOUNT;
    //     vm.startPrank(address(0xb11));
    //     usdt.approve(address(kventure),fee);
    //     kventure.Register(phone,codeRoot,0,bytes32(0),address(0xb11));
    //     bytes32 code0xb11 = kventure.GetCodeRef();
    //     vm.stopPrank();
    //     assertEq(
    //         usdt.balanceOf(address(0xb11)),
    //         0,
    //         "Error balance "
    //     );

    //     //address 0xb12 order 
    //     vm.startPrank(address(0xb12));
    //     usdt.approve(address(product),10000*USDT_AMOUNT);

    //     bytes32[] memory idArr = new bytes32[](1);
    //     idArr[0] = ProductArr[0].id;
    //     uint256[] memory quaArr = new uint256[](1);
    //     quaArr[0]=1;
    //     bool[] memory lockArr = new bool[](1);
    //     lockArr[0]=false;
    //     bytes32[] memory codeHash = new bytes32[](1);
    //     codeHash[0] = bytes32("234");
    //     bytes32[][] memory codeHashes = new bytes32[][](1);
    //     codeHashes[0] = codeHash;
    //     bool[] memory cloudMinings = new bool[](1);
    //     cloudMinings[0]=false;
    //     address[] memory delegates = new address[](1);
    //     delegates[0]=address(0);

    //     product.order(idArr,quaArr,lockArr,codeHashes,cloudMinings,delegates,code0xb11,address(0xb12));
    //     vm.stopPrank();
    //     assertEq(
    //         usdt.balanceOf(address(0xb12)),
    //         (10000*USDT_AMOUNT-6108*USDT_AMOUNT*92/100),
    //         "Error balance "
    //     ); 
    //     assertEq(
    //         kventure.GetUserInfo(address(0xb11)).totalCareerBonus,
    //         110800000,
    //         "Error balance "
    //     ); 

  
    // }
}
