// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC721/IERC721.sol";
import "./AbstractPackage.sol";
import "./GenerateCode.sol";
import {KVenture} from "./kventure.sol";
import "forge-std/Test.sol";
// import "hardhat/console.sol";
interface IKventureCode{
    function GenerateCode(
        uint planPrice,
        uint quantity,
        bool lock,
        bytes32[] calldata codeHashes,
        bool _cloudMining,
        address _delegate
        // bytes32 codeRef
    ) external returns (uint[] memory);
}
contract Product is Initializable, OwnableUpgradeable, PackageInfoStruct{
    Order orderPro;
    Product [] public products;
    mapping(address => bool) public isAdmin;
    uint256 public totalProduct;
    address public usdt;
    address public masterPool;
    KVenture public ref;
    KventureCode public kventureCode;
    mapping(address => bytes32[]) public mOrderArr;
    mapping(bytes32 idProduct => Product) public mProduct; //id product => Product
    mapping(bytes32 idOrder => Order) public mOrder; // id Order => Order
    mapping(uint256 tokenIdNft => Product) public mIdToPro; // tokenid nft => Product
    event SaleOrder(address buyer,bytes32 orderId,bytes32[] productIds, uint256[] quantities);
    uint8 public returnRIP = 10;

    constructor() payable {}
    modifier onlyAdmin() {
        require(isAdmin[msg.sender]==true , "Invalid caller-Only Admin");
        _;
    }
    function initialize(
        address _trustedUSDT,
        address _masterPool,
        // address _trustedNFT,
        address _kventureCode,
        address _ref
    ) public initializer {
        usdt = _trustedUSDT;
        masterPool = _masterPool;
        // nft = _trustedNFT;
        kventureCode = KventureCode(_kventureCode);
        ref = KVenture(_ref);
        __Ownable_init();
    }
    function SetKventureCode(address _kventureCode) external onlyOwner {
        kventureCode = KventureCode(_kventureCode);
    }
    function SetRef(address _kventure) external onlyOwner {
        ref = KVenture(_kventure);
    }
    function SetUsdt(address _usdt) external onlyOwner {
        usdt = _usdt;
    } 
    function SetAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
    } 
    function SetMasterPool(address _masterPool) external onlyOwner {
        masterPool = _masterPool;
    }
    function shippingInfo(
        bytes32 _orderId,
        string memory _fullname,
        string memory _add,
        string memory _phone,
        string memory _zipcode,
        string memory _email,
        uint256  _receivingTime
    )external {
        require(mOrder[_orderId].buyer == msg.sender,"only owner of order can call");
        ShippingInfo memory shipInfo = ShippingInfo({
            // orderId:_orderId,
            fullname:_fullname,
            add:_add,
            phone:_phone,
            zipcode:_zipcode,
            email:_email,
            receivingTime:_receivingTime
        });
        mOrder[_orderId].shipInfo= shipInfo;

    }
    function getShipInfo(bytes32 _orderId)external view returns(ShippingInfo memory){
        return mOrder[_orderId].shipInfo;
    }

function order(
        bytes32[] memory idArr, 
        uint256[] memory quaArr,
        bool[] memory lockArr,
        bytes32[][] calldata codeHashes,
        bool[] memory cloudMinings,
        address[] memory delegates,
        bytes32 codeRef,
        address to
    ) external returns(bytes32){
        // If to is member or buy using code ref 
        require(ref.CheckActiveMember(to) || ref.GetRefCodeOwner(codeRef) != address(0),"Non member can not order");
        require(quaArr.length == idArr.length && quaArr.length == lockArr.length && lockArr.length == codeHashes.length 
        && codeHashes.length == cloudMinings.length && cloudMinings.length == delegates.length
        ,"lengths of arrays not equal");
        
        uint256 memPrice;
        uint256 retailPrice;
        for(uint i = 0;i < idArr.length;i++){
            require(mProduct[idArr[i]].memberPrice > 0," product id does not exist ");
            memPrice += mProduct[idArr[i]].memberPrice * quaArr[i];
            retailPrice += mProduct[idArr[i]].retailPrice * quaArr[i];

        }
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender,to,idArr.length,block.timestamp));
        uint[] memory codesArr = _getTokenIdArr(idArr,quaArr,lockArr,codeHashes,cloudMinings,delegates);
        mOrderArr[to].push(orderId);
        mOrder[orderId].id= orderId;
        mOrder[orderId].buyer= to;
        mOrder[orderId].productIds= idArr;
        mOrder[orderId].quantities = quaArr;
        mOrder[orderId].creatAt= block.timestamp;
        mOrder[orderId].tokenIds= codesArr;
        mOrder[orderId].paymentAdd= msg.sender;

        {
            // Flow Member Price
            // address referrerWallet; 
            address menberBonusWallet = to; 
            // This is link price or member price
            uint256 actualPrice = memPrice;
            if (!ref.CheckActiveMember(to)) {
                // Discount 8% and set link price
                retailPrice = retailPrice * 92 / 100;
                actualPrice = retailPrice;
                menberBonusWallet = ref.GetRefCodeOwner(codeRef); 
            }

            // Sender transfer to master pool
            // End Flow Member Price
            require(
                IERC20(usdt).balanceOf(msg.sender) >= actualPrice,
                "Kventure: Invalid Balance"
            );
            IERC20(usdt).transferFrom(msg.sender, masterPool, actualPrice);

            if (!ref.CheckActiveMember(to)) {  //khi buyer not member
                console.log("kkkkkkkkkkk");
                ref.TransferRetailBonus(menberBonusWallet, actualPrice - memPrice);
            }

            ref.TransferCommssion(menberBonusWallet, memPrice, retailPrice - memPrice);
        }

        // emit SaleOrder(to,orderId,idArr,quaArr);
        return orderId;
    }
    
    function _getTokenIdArr(
        bytes32[] memory idArr, 
        uint256[] memory quaArr,
        bool[] memory lockArr,
        bytes32[][] calldata codeHashes,
        bool[] memory cloudMinings,
        address[] memory delegates
        // uint256 _totalQuantity
    )internal returns(uint[] memory){
        uint totalQuantity;
        for(uint i=0;i<idArr.length;i++){
            totalQuantity += quaArr[i];
        }
        uint256 offset =0;
        uint[] memory codesArr = new uint[](totalQuantity);
        for(uint i=0;i< idArr.length;i++){
            uint[] memory codes = new uint[](quaArr[i]);
            codes =_order(idArr[i],quaArr[i],lockArr[i],codeHashes[i],cloudMinings[i],delegates[i]);

            for(uint j=0;j<codes.length;j++){
                codesArr[offset+j]= codes[j];
            }
            offset += quaArr[i];
        }
        return codesArr;
    }
    function _order(
        bytes32 _productId,
        uint256 _quantity,
        bool _lock,
        bytes32[] calldata _codeHashes,
        bool _cloudMining,
        address _delegate
        // bytes32 codeRef
        )internal returns(uint[] memory) {
        require (mProduct[_productId].id != bytes32(0),"product id does not exist");
        require(_quantity>0,"quantity wrong");
        uint[] memory codes = new uint[](_quantity);
        codes = kventureCode.GenerateCode(
            msg.sender,
            mProduct[_productId].memberPrice,
            _quantity,
            _lock,
            _codeHashes,
            _cloudMining,
            _delegate
        );
        for(uint256 i=0;i<codes.length;i++){
            mIdToPro[codes[i]] = mProduct[_productId];

        }
        return codes;
    }
    function getNftDetail(uint _tokenId)public view returns(Product memory){
        return mIdToPro[_tokenId];
    }
    function getOrdersInfo(address buyer, uint256 page) public view returns(bool isMore, Order[] memory orderList){
            if (page * returnRIP > mOrderArr[buyer].length + returnRIP) {
                return (false, orderList);
            } else {
                if (page * returnRIP < mOrderArr[buyer].length) {
                    isMore = true;
                    orderList = new Order[](returnRIP);
                    for (uint i = 0; i < orderList.length; i++) {
                        orderList[i] = mOrder[
                            mOrderArr[buyer][page * returnRIP - returnRIP + i]
                        ];
                    }
                    return (isMore, orderList);
                } else {
                    isMore = false;
                    orderList = new Order[](
                        returnRIP - (page * returnRIP - mOrderArr[buyer].length)
                    );
                    for (uint i = 0; i < orderList.length; i++) {
                        orderList[i] = mOrder[
                            mOrderArr[buyer][page * returnRIP - returnRIP + i]
                        ];
                    }
                    return (isMore, orderList);
                }
            }
        }

    // function getIdOrderArr()external view returns(bytes32[] memory){
    //     return mOrderArr;
    // }
    function getOrderInfoById(bytes32 orderId)public view returns(Order memory){
        return mOrder[orderId];
    }
    function adminAddProduct(
        string memory _imgUrl,
        uint256 _memberPrice,
        uint256 _retailPrice,
        string memory _desc,
        bool  _status     
    ) external onlyAdmin   {
        bytes32 idPro = keccak256(abi.encodePacked(_imgUrl,_memberPrice,_retailPrice,_desc));
        Product memory product = Product({
            id: idPro,
            imgUrl: bytes(_imgUrl),
            memberPrice: _memberPrice,
            retailPrice: _retailPrice,
            desc: bytes(_desc),
            active: _status
        });
        
        products.push(product);
        mProduct[idPro] = product;
        totalProduct++;
    }
    function findProductIndexById(bytes32 _id) public view returns (uint256) {
    for (uint256 i = 0; i < products.length; i++) {
        if (_id == products[i].id) {
            return i;  // Return the index of the product with the specified id
        }
    }
    revert("Product not found");  // Revert if the product with the specified id is not found
    }
    function getProductById(bytes32 _id) public view returns(Product memory){
        return mProduct[_id];
    }

    function adminUpdateProduct(
        bytes32 idProduct,
        bytes memory _newImgUrl,
        bytes memory _newDesc,
        bool _newStatus
    )external  onlyAdmin{
        uint index = findProductIndexById(idProduct);
        Product memory product =products[index];
        if(!compareBytes(_newImgUrl,product.imgUrl) && _newImgUrl.length != 0){
           product.imgUrl = _newImgUrl;
           
        }
        if(!compareBytes(_newDesc,product.desc) && _newDesc.length !=0){
           product.desc = _newDesc;
        }
        if(_newStatus != product.active){
           product.active = _newStatus;
        }
        products[index] = product;
        mProduct[idProduct]=products[index];
    }
    function compareBytes(bytes memory _bytes1, bytes memory _bytes2) internal pure returns (bool) {
        // Check if the lengths of the byte arrays are equal
        if (_bytes1.length != _bytes2.length) {
            return false;
        }
        
        // Iterate over each byte in the byte arrays and compare their values
        for (uint256 i = 0; i < _bytes1.length; i++) {
            if (_bytes1[i] != _bytes2[i]) {
                return false; // Bytes arrays are not equal
            }
        }      
        return true; // Bytes arrays are equal
    }
    function adminViewProduct()external view onlyAdmin returns (Product[] memory){
        return products;
    }
    function userViewProduct()external view returns(Product[] memory) {
        uint256 activeCount=0;
        for (uint i=0;i < products.length;i++){
            if(products[i].active == true){
                activeCount++;
            }
        }
        Product [] memory userProducts = new Product [](activeCount);
        uint256 count=0;
        
        for (uint i=0;i < products.length;i++){
            if(products[i].active == true){
                userProducts[count]=products[i];
                count++;
            }
            
        }

        return userProducts;
    }

}