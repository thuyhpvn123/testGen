// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import "./AbstractPackage.sol";
interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeMint(address to, uint256 tokenId) external;
    function burnByController(uint tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view  returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IMinterSmC {
    function CheckDelegateAddress(
        address _delegate
    ) external view returns (bool); //Function to check delagate claim for MTI

    function CheckDelegateAddressAndType(
        address _delegate,
        bytes32 _types
    ) external view returns (bool);
}

contract KventureCode is Initializable, OwnableUpgradeable, PackageInfoStruct {
    uint public rateBoost = 1 * usdtDecimal; // 1$ = 1%;
    uint256 public usdtDecimal = 10 ** 6;
    uint256 public boostSpeedDecimal = 10 ** 2;
    uint256 public KCodePrice = usdtDecimal * 30;
    uint32 public returnRIP = 10;
    mapping(bytes32 => PackageInfo) mPackageInfo;
    // mapping(uint256 => SubscriptionType) public mValidType;
    mapping(uint256 => uint256) public mValidMiningTime;
    uint256 cloudMiningThreshold;

    uint public deployedDate;

    address public usdt;
    address public boostStorage;
    address public masterPool;
    address public nft;
    address public kventure;
    IMinterSmC public minter;
    address public product;
    mapping(uint => Product) public mIdToPro;

    constructor() payable {}

    function initialize(
        address _trustedUSDT,
        address _masterPool,
        address _minter,
        address _boostStorage,
        address _product,
        address _trustedNFT,
        address _kventure
    ) public initializer {
        usdt = _trustedUSDT;
        masterPool = _masterPool;
        minter = IMinterSmC(_minter);
        boostStorage = _boostStorage;
        kventure = _kventure;
        product = _product;
        nft = _trustedNFT;
        __Ownable_init();

        // returnRIP = 10;
        usdtDecimal = 10 ** 6;
        boostSpeedDecimal = 10 ** 2;
        rateBoost = 1 * usdtDecimal; // 1$ = 1%
        _initializeConfig();
        deployedDate = block.timestamp;
    }

    modifier onlyBoostStorage() {
        require(msg.sender == boostStorage, "Kventure: Only boost storage");
        _;
    }

    modifier onlyKventure() {
        require(msg.sender == kventure, "Kventure: Only kventure");
        _;
    }
    
    modifier onlyProduct() {
        require(msg.sender == product, "Kventure: Only product");
        _;
    }
    function SetNFT(address _nft) external onlyOwner {
        nft = _nft;
    }

    function SetUsdt(address _usdt) external onlyOwner {
        usdt = _usdt;
    } 
    function SetMasterPool(address _masterPool) external onlyOwner {
        masterPool = _masterPool;
    }
    function SetProduct(address _product) external onlyOwner {
        product = _product;
    }
    function SetCloudMiningThreshold(uint256 _cloudMiningThreshold) external onlyOwner {
        cloudMiningThreshold = _cloudMiningThreshold;
    }

    function _initializeConfig() internal {
        cloudMiningThreshold = 5_000 * usdtDecimal;

        // // Code $500
        // mValidType[500 * usdtDecimal] = SubscriptionType.Builder;
        // mValidMiningTime[500 * usdtDecimal] = 90 days;

        // // Code $1000
        // mValidType[1000 * usdtDecimal] = SubscriptionType.Professional;
        // mValidMiningTime[1_000 * usdtDecimal] = 120 days;

        // // Code $5000
        // mValidType[5000 * usdtDecimal] = SubscriptionType.Executive;
        // mValidMiningTime[5_000 * usdtDecimal] = 180 days;

        // // Code $10_000
        // mValidType[10_000 * usdtDecimal] = SubscriptionType.Elite;
        // mValidMiningTime[10_000 * usdtDecimal] = 270 days;

        // // Code $20_000
        // mValidType[20_000 * usdtDecimal] = SubscriptionType.Manager;
        // mValidMiningTime[20_000 * usdtDecimal] = 360 days;

        // // Code $50_000
        // mValidType[50_000 * usdtDecimal] = SubscriptionType.President;
        // mValidMiningTime[50_000 * usdtDecimal] = 360 days;

        // // Code $100_000
        // mValidType[100_000 * usdtDecimal] = SubscriptionType.CEO;
        // mValidMiningTime[100_000 * usdtDecimal] = 360 days;
    }

    function CalculateCurrentRateBoost() public view returns (uint) {
        uint256 currentRateBoost = rateBoost;
        uint count = (block.timestamp - deployedDate) / 60 days;
        for (uint16 index = 0; index < count; index++) {
            currentRateBoost = (currentRateBoost * 125) / 100;
        }
        return currentRateBoost;
    }

    function GenerateCode(
        address buyer,
        uint planPrice,
        uint quantity,
        bool lock,
        bytes32[] calldata codeHashes,
        bool _cloudMining,
        address _delegate
        // bytes32 codeRef
    ) external onlyProduct returns (uint[] memory) {
        require(
            codeHashes.length == quantity && quantity > 0,
            "Kventure: Code Hash Not Equal To Quantity or Quantity Smaller Than 1"
        );
        // require(_validatePrice(planPrice), "Invalid price");
        if (_cloudMining) {
            require(
                planPrice >= cloudMiningThreshold,
                "Kventure: Cloud Mining Only For Package Above $5000"
            );
            require(
                minter.CheckDelegateAddressAndType(_delegate, keccak256(abi.encodePacked("KVENTURE"))),
                "Kventure: Invalid delegate address"
            );
        } else {
            require(_delegate == address(0), "Kventure: Only for cloud mining");
        }

        uint currentRateBoost = CalculateCurrentRateBoost();
        uint [] memory codes = new uint[](quantity); 
        for (uint i = 0; i < quantity; i++) {
            uint code = _generateCode(
                buyer,
                codeHashes[i],
                lock,
                planPrice,
                currentRateBoost,
                _cloudMining,
                _delegate
            );
            codes[i]=code;
        }

        return codes;
    }


    function KGenerateCode(
        address buyer,
        bytes32 codeHash
    ) external onlyKventure returns (bool) {
        _generateCode(
            buyer,
            codeHash,
            false,
            KCodePrice,
            CalculateCurrentRateBoost(),
            false,
            address(0)
        );
        return true;
    }

    function _generateCode(
        address buyer,
        bytes32 codeHash,
        bool _lock,
        uint _planPrice,
        uint _rateBoost,
        bool _cloudMining,
        address _delegate
    ) internal returns(uint){
        require(
            mPackageInfo[codeHash].owner == address(0),
            "MetaNode: Duplicate Code Hash"
        );
        uint code = uint(codeHash);
        mPackageInfo[codeHash] = PackageInfo({
            code: code,
            codeHash: codeHash,
            activeTime: 0,
            expirationTime: 0,
            expirationActiveTime: block.timestamp + 90 days,
            status: _isBlock(_lock),
            planPrice: _planPrice,
            boostSpeed: (_planPrice * boostSpeedDecimal) / _rateBoost,
            boostTime: mValidMiningTime[_planPrice],
            owner: buyer,
            rateBoost: _rateBoost,
            cloudMining: _cloudMining,
            delegate: _delegate
        });
        INFT(nft).safeMint(buyer,code);
        // MTI sẽ gọi chi trả hoa hồng chỗ  này (Tùy theo quy luật chi trả hoa hồng để  chọn ví trị gọi hàm chi trả hoa hồng)
        return code;
    }

    // function _validatePrice(uint planPrice) internal view returns (bool) {
    //     return mValidType[planPrice] != SubscriptionType.None;
    // }

    function UnblockManyCode(
        string[] calldata codeFEs
    ) external returns (bool[] memory) {
        bool[] memory success = new bool[](codeFEs.length);
        bytes32 codeHash;
        for (uint index = 0; index < codeFEs.length; index++) {
            codeHash = keccak256(abi.encodePacked(codeFEs[index]));
            if (
                msg.sender != mPackageInfo[codeHash].owner ||
                mPackageInfo[codeHash].status == PackageStatus.Unblock
            ) {
                continue;
            }
            mPackageInfo[codeHash].status = PackageStatus.Unblock;
            success[index] = true;
        }
        return success;
    }

    function BlockManyCode(
        string[] calldata codeFEs
    ) external returns (bool[] memory) {
        bool[] memory success = new bool[](codeFEs.length);
        bytes32 codeHash;
        for (uint8 index = 0; index < codeFEs.length; index++) {
            codeHash = keccak256(abi.encodePacked(codeFEs[index]));
            if (
                msg.sender != mPackageInfo[codeHash].owner ||
                mPackageInfo[codeHash].status == PackageStatus.Block
            ) {
                continue;
            }
            mPackageInfo[codeHash].status = PackageStatus.Block;
            success[index] = true;
        }
        return success;
    }

    function _isBlock(bool lock) internal pure returns (PackageStatus) {
        return lock ? PackageStatus.Block : PackageStatus.Unblock;
    }

    function getCodeInfoSmC(
        bytes32 codeHash
    ) external view returns (PackageInfo memory) {
        return mPackageInfo[codeHash];
    }

    // OnlyCodeStorage
    function activateCode(
        bytes32 code
    ) external onlyBoostStorage returns (bool) {
        mPackageInfo[code].status = PackageStatus.Active;
        mPackageInfo[code].activeTime = block.timestamp;
        mPackageInfo[code].expirationTime =
            block.timestamp +
            mPackageInfo[code].boostTime;
        return true;
    }

    // OnlyCodeStorage
    function handleExpiredCode(
        bytes32 code
    ) external onlyBoostStorage returns (bool) {
        mPackageInfo[code].status = PackageStatus.Expired;
        return true;
    }

    function GetMyCode(uint32 _page) 
    external 
    view 
    returns(bool isMore, PackageInfo[] memory arrayPack) {
        uint length = INFT(nft).balanceOf(msg.sender);
        if (_page * returnRIP > length + returnRIP) { 
            return(false, arrayPack);
        } else {
            if (_page*returnRIP < length ) {
                isMore = true;
                arrayPack = new PackageInfo[](returnRIP);
                for (uint i = 0; i < arrayPack.length; i++) {
                        arrayPack[i] = mPackageInfo[bytes32(INFT(nft).tokenOfOwnerByIndex(msg.sender,_page*returnRIP - returnRIP +i))];
                }
                return (isMore, arrayPack);
            } else {
                isMore = false;
                arrayPack = new PackageInfo[](returnRIP -(_page*returnRIP - length));
                 for (uint i = 0; i < arrayPack.length; i++) {
                    arrayPack[i] = mPackageInfo[bytes32(INFT(nft).tokenOfOwnerByIndex(msg.sender,_page*returnRIP - returnRIP +i))];
                }
                return (isMore, arrayPack);
            }
        }
    }

    function GetUserCode(uint32 _page, address _user) 
    external onlyOwner
    view 
    returns(bool isMore, PackageInfo[] memory arrayPack) {
        uint length = INFT(nft).balanceOf(_user);
        if (_page * returnRIP > length + returnRIP) { 
            return(false, arrayPack);
        } else {
            if (_page*returnRIP < length ) {
                isMore = true;
                arrayPack = new PackageInfo[](returnRIP);
                for (uint i = 0; i < arrayPack.length; i++) {
                        arrayPack[i] = mPackageInfo[bytes32(INFT(nft).tokenOfOwnerByIndex(_user,_page*returnRIP - returnRIP +i))];
                }
                return (isMore, arrayPack);
            } else {
                isMore = false;
                arrayPack = new PackageInfo[](returnRIP -(_page*returnRIP - length));
                 for (uint i = 0; i < arrayPack.length; i++) {
                    arrayPack[i] = mPackageInfo[bytes32(INFT(nft).tokenOfOwnerByIndex(_user,_page*returnRIP - returnRIP +i))];
                }
                return (isMore, arrayPack);
            }
        }
    }

    function GetTotalMyCode() external view returns(uint) {
        return INFT(nft).balanceOf(msg.sender);
    }
}