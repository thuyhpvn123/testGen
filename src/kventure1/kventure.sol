// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import {IMasterPool} from "./MasterPool.sol";
import "@openzeppelin/contracts@v4.9.0/utils/math/Math.sol";
import {IBinaryTree} from "./interfaces/IBinaryTree.sol";
import {KventureCode} from "./GenerateCode.sol";
import "./AbstractPackage.sol";
import {console} from "forge-std/console.sol";

contract KVenture is Initializable, OwnableUpgradeable,PackageInfoStruct {
    struct SubcribeInfo {
        bytes32 codeRef;
        bytes32 phone;
    } 
    struct Generation{
        uint64 Silver;
        uint64 Gold;
        uint64 Platinum;
        uint64 Diamond; 
    }
    address public usdt;
    address public masterPool;
    IBinaryTree public binaryTree;
    KventureCode public kCode;
     
    address public packageController;
    address public root;
    // address public product;

    uint public totalUser;
    enum Rank {Unranked, Bronze, Silver,Gold,Platinum,Diamond,crownDiamond}
    mapping(address => Generation) public mGenerations;
    mapping(address => uint8)public ranks; //0-6
    mapping(bytes32 => address) public mRefCode;
    mapping(address => SubcribeInfo) public mSubInfo;
    mapping(address => address[]) public childrens;
    mapping(address => address[]) public childrensMatrix;
    mapping(address => address) public line; //parent
    mapping(address => address) public lineMatrix; //parent matrix    //nhớ xoá public
    mapping(address => bool) isActive;
    mapping(address => uint256) firstTimePay;
    mapping(address => uint256) nextTimePay;
    mapping(address => bool) public mSub;
    mapping(address => bytes32) public mphone;
    mapping(address => uint256) public mtotalMember;
    uint256[] public totalMemberRequiedToRankUps ;  
    uint256[] public totalMemberF1RequiedToRankUps ;         
    uint256 public RankUpdateBranchRequired ;
    uint256[] public totalMaxMembers1BranchToRankUp;

    uint256[] public comDirectRate; //0.5% => (5% / 10) = 5/(10^3) 
    uint256 public adDirectRate;
    uint256 comMatrixRate;
    uint256[] public comMatchingRate;
    uint256 public usdtDecimal; 
    uint registerFee ;
    uint subcriptionFee ;
    uint32 public day; 

    event Subcribed(address user,uint id);
    event PayBonus(address sub, uint amountUsdt, uint date, string typ);

    uint256 public totalSubscriptionPayment; 
    uint256 public totalMatrixPayment; 
    uint256 public totalMatchingPayment; 
    uint256 maxDirectRateBonus;
    uint256 maxMatrixRateBonus;
    uint256 matrixCompanyRateBonus;

    uint256 public maxLineForMatrixBonus ;

    uint256[] public commissionRate; //0.5% => (5% / 10) = 5/(10^3) 
    uint256[] public levelCareerBonus;   
    uint256 public totalUniLvlPayment;
    uint256 public totalCareerPayment;
    uint256 public totalExtraDiamondPayment;
    uint256 public totalExtraCrownDiamondPayment;

    uint256 totalSaleRevenue;
    mapping(address => uint256) public totalSubcriptionBonus;
    mapping(address => uint256) public totalMatrixBonus;
    mapping(address => uint256) public totalMatchingBonus;
    mapping(address => uint256) public totalUniLevelBonus;
    mapping(address => uint256) public totalCareerBonus;
    mapping(address => uint256) public totalExtraDiamondBonus;
    mapping(address => uint256) public totalExtraCrownDiamondBonus;

    mapping(address => uint256) public totalRevenues;
    mapping(address => uint256) public totalSale;

    mapping(address => mapping(uint8 => bool)) public mIsPaiedCareerBonus; // parent address => level => isClaimed Commission Bonus
    mapping(address => uint256) public currentRevenueForGoodSaleBonus;
    uint256 additionalCom ;
    mapping(address => bool) public isAdmin;
    address [] diamondArr;
    address [] crownDiamondArr;
    uint256 diamondRate;
    uint256 crownDiamondRate;
    uint256 LNrate;
    struct UserInfo{
        address add;
        bool IsActive;
        uint256 FirstTimePay;
        uint256 NextTimePay;
        bytes32 Mphone;
        address[] Childrens;
        address[] ChildrensMatrix;
        address Line; //parent
        address LineMatrix;
        uint256 MtotalMember;
        uint256 Rank;
        uint256 totalSubcriptionBonus;
        uint256  totalMatrixBonus;
        uint256  totalMatchingBonus;
        uint256  totalUniLevelBonus;
        uint256  totalCareerBonus;
        uint256  totalExtraDiamondBonus;
        uint256  totalExtraCrownDiamondBonus;
        uint256 totalSale;
    }
    // UserInfo userinfo;
    address public wallet; // Corporation Wallet (IBe)
    uint256 timeInActive;
    address public partnerWallet;
    uint256 public PartnerDebt;

    constructor() payable {}
    function initialize(address _usdt, address _masterPool,address _binaryTree,address _root, address _wallet, address _partnerWallet, address _kCode) public initializer {
        usdt = _usdt;
        masterPool = _masterPool;
        binaryTree = IBinaryTree(_binaryTree);
        kCode = KventureCode(_kCode);
        root = _root;
        __Ownable_init();

        totalMemberRequiedToRankUps =[0,2,20,100,500,2_500,50_000];
        totalMemberF1RequiedToRankUps = [0,2,10,30,100];
        totalMaxMembers1BranchToRankUp = [0,0,0,30,150,500,10_000];
        RankUpdateBranchRequired = 3;
        // comDirectRate = [500, 100, 50, 50, 30, 20, 20, 10, 10, 10]; //0.5% => (5% / 10) = 5/(10^3) 
        comDirectRate = [500,100, 50, 50, 30, 20, 20, 10, 10, 10]; //0.5% => (5% / 10) = 5/(10^3) 
        adDirectRate = 175;
        comMatrixRate = 25;
        maxDirectRateBonus = 800;
        maxMatrixRateBonus = 825;
        matrixCompanyRateBonus = 150;
        comMatchingRate = [500, 100, 50, 50, 30];

        usdtDecimal = 10**6; 
        registerFee = 40 * usdtDecimal;
        subcriptionFee =10 * usdtDecimal;
        day = 1;
        maxLineForMatrixBonus = 15;
        //sale bonus
        commissionRate = [500,100,50,50,30,20,20,10,10,10];
        // levelCareerBonus = [9_000, 18_000, 36_000, 90_000, 180_000];
        levelCareerBonus = [300, 600, 1_200, 3_000, 6_000];
        additionalCom = 100;
        diamondRate = 20;
        crownDiamondRate = 5;
        LNrate = 295;
        isAdmin[msg.sender] = true;
        timeInActive = 30 days;
        _initiationForRoot();

        wallet = _wallet; // Set Corporation Wallet
        partnerWallet = _partnerWallet; 
    }
    modifier onlyPackController() {
        require(msg.sender == packageController, "Invalid caller-onlyPackController");
        _;
    }
    modifier onlySub() {
        require(mSub[msg.sender] == true, 'MetaNode: Please Subcribe First');
        _;
    }
    modifier onlyAdmin() {
        require(isAdmin[msg.sender]==true , "Invalid caller-Only Admin");
        _;
    }
    // modifier onlyProduct() {
    //     require(msg.sender == product, "Invalid caller-onlyProduct");
    //     _;
    // }
    // function changePhone(bytes32 _newPhone)external{
    //     require(mSub[msg.sender] == true, "Not Registered yet");
    //     mphone[msg.sender] =_newPhone;
    // }
    function SetWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    } 
    function SetTimeInActive(uint256 _time) external onlyOwner {
        timeInActive = _time;
    } 
    function SetAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
    } 
    function SetBinaryTree(address _binaryTree) external onlyOwner {
        binaryTree = IBinaryTree(_binaryTree);
    } 
    function SetUsdt(address _usdt) external onlyOwner {
        usdt = _usdt;
    } 
    function SetMasterPool(address _masterPool) external onlyOwner {
        masterPool = _masterPool;
    }
    function SetSubFee(uint _subFee) external onlyOwner {
        subcriptionFee = _subFee;
    }
    function SetRegisterFee(uint _registerFee) external onlyOwner {
        registerFee = _registerFee;
    }
    function SetPackageController(address _packageController) external onlyOwner {
        packageController = _packageController;
    }
    // function SetProduct(address _product) external onlyOwner {
    //     product = _product;
    // }
    function _initiationForRoot() internal {
        _createSubscriptionRoot();
        binaryTree.init(root,1);
    }

    function _createSubscriptionRoot() internal {
        require(line[root] == address(0),"this address is used");
        totalUser++;
        mSub[root] = true;
        mSubInfo[root] = SubcribeInfo({
            codeRef: keccak256(abi.encodePacked(root,block.timestamp, block.prevrandao,totalUser)),
            phone: bytes32(0)
        });
        mRefCode[mSubInfo[root].codeRef] = root;

        ranks[root] = 0;
        firstTimePay[root] = block.timestamp;
        nextTimePay[root] = firstTimePay[root] + timeInActive;
        isActive[root] = true;
        emit Subcribed(root,totalUser);
    }
    event eAddHeadRef(address user, bytes32 codeRef);
    function _addHeadRef(address sender, bytes32 codeRef)  internal   {
        // require(mSub[sender] == false, "MetaNode: Only for non-subscribers");
        require(mRefCode[codeRef] != address(0), 'MetaNode: Invalid Refferal Code');
        line[sender] = mRefCode[codeRef];
        emit eAddHeadRef(sender, codeRef);
    }

    function Register(bytes32 phone,bytes32 codeRef, uint256 month, bytes32 codeHash,address to) external returns(bool) {
        require(mSub[to] == false, "Registered");
        _addHeadRef(to,codeRef);
        uint256 firstFee = registerFee + subcriptionFee;
        uint256 transferredAmount = month * subcriptionFee;
        uint256 totalPayment = firstFee + transferredAmount; 
        require(IERC20(usdt).balanceOf(msg.sender) >= totalPayment, "Invalid Balance");
        IERC20(usdt).transferFrom(msg.sender,masterPool,totalPayment);
        _addBinaryTree(to);
        _createSubscription(to,firstFee,phone);

        _transferMatrixBonus(to,transferredAmount);
        firstTimePay[to] = block.timestamp;
        nextTimePay[to] = nextTimePay[to] + timeInActive * month;
        _bonusForDiamond(transferredAmount);
        _bonusForCrownDiamond(transferredAmount);

        if (month>10) {
            PartnerDebt += 30 * usdtDecimal;
            kCode.KGenerateCode(to, codeHash);
        }
        
        return true;
    }

    function _createSubscription(address subscriber,uint transferredAmount,bytes32 phone) internal {
        totalUser++;
        mSub[subscriber] = true;
        mphone[subscriber] = phone;
        mSubInfo[subscriber] = SubcribeInfo({
            codeRef: keccak256(abi.encodePacked(subscriber,block.timestamp, block.prevrandao,totalUser)),
            phone: phone
        });
        mRefCode[mSubInfo[subscriber].codeRef] = subscriber;

        address parent = line[subscriber];
        if (parent != address(0)) {
            childrens[parent].push(subscriber);
            line[subscriber] = parent;
            _transferDirectCommission(subscriber,transferredAmount);
        }
        ranks[subscriber] = 0;
        firstTimePay[subscriber] = block.timestamp;
        nextTimePay[subscriber] = firstTimePay[subscriber] + timeInActive;
        isActive[subscriber] = true;
        _addMemberLevels(subscriber);
        _bonusForDiamond(transferredAmount);
        _bonusForCrownDiamond(transferredAmount);

        emit Subcribed(subscriber,totalUser);
    }
    function _addMemberLevels(address subscriber)internal{
            address parentAddress = line[subscriber];
            while(parentAddress != address(0))
            {
                mtotalMember[parentAddress] += 1;
                // _updateRank(parentAddress);
                parentAddress = line[parentAddress];
            }
    }

    function _addBinaryTree(address to) internal {
        address pAddress = binaryTree.addNode(line[to], to);
        childrensMatrix[pAddress].push(to);
        lineMatrix[to] = pAddress;
    }

    function _transferDirectCommission(address buyer,uint256 _firstFee) internal {
        address parentMatrix = lineMatrix[buyer];
        address parentDirect = line[buyer];
        uint commAmount;
        uint commAmountFA;
        bool success; 
        //pay to company
        uint256 amount = (adDirectRate*_firstFee) / 10**3;
        uint256 maxAmountBonus = (maxDirectRateBonus*_firstFee) / 10**3;

        uint totalAmountTransfer = 0;
        success = IMasterPool(masterPool).transferCommission(wallet, amount);
        require(success, "Failed transfer direct commission"); 
        
        //pay 50% for F1
        commAmountFA = (comDirectRate[0]*_firstFee) / 10**3;
        if(isActive[parentDirect] == false){
            success = IMasterPool(masterPool).transferCommission(wallet, commAmountFA);
        } else {
            IMasterPool(masterPool).transferCommission(parentDirect, commAmountFA);
            emit PayBonus(parentDirect, commAmountFA, block.timestamp,"Direct");            
        }
        totalAmountTransfer += commAmountFA;
        totalSubscriptionPayment += commAmountFA;
        //pay to users in system
        for (uint index = 1; index < comDirectRate.length; index++) 
        {   
            if (parentMatrix == address(0)) {
                IMasterPool(masterPool).transferCommission(wallet, maxAmountBonus - totalAmountTransfer);
                break;
            }
           

            // 9 level from 1 to 10
            commAmount = (comDirectRate[index]*_firstFee) / 10**3;
          
            if (_isValidLevel(parentMatrix,index) && isActive[parentMatrix] == true) {   
                // Pay commission by subscription
                IMasterPool(masterPool).transferCommission(parentMatrix, commAmount);
                emit PayBonus(parentMatrix, commAmount, block.timestamp,"Direct");            
                totalSubcriptionBonus[parentMatrix] += commAmount;
            } else {
                IMasterPool(masterPool).transferCommission(wallet, commAmount);
            }
            totalAmountTransfer += commAmount;
            totalSubscriptionPayment += commAmount;

            // next iteration
            parentMatrix = lineMatrix[parentMatrix];
        }
    }
    
    function PaySub (uint256 monthsNum,address to) external returns (bool) {
        require(isActive[to]==true,"this address is not active anymore");
        require(monthsNum>=1 && monthsNum<=36,"invalid number of month");
        require(mSub[to] == true, "Need to register first");
        require(IERC20(usdt).balanceOf(msg.sender) >= subcriptionFee, "Invalid Balance");
        uint256 transferredAmount = subcriptionFee*monthsNum;
        IERC20(usdt).transferFrom(msg.sender,masterPool,transferredAmount);
        _transferMatrixBonus(to,transferredAmount);
        // firstTimePay[to] = block.timestamp;
        nextTimePay[to] = nextTimePay[to] + timeInActive *monthsNum;
        _bonusForDiamond(transferredAmount);
        _bonusForCrownDiamond(transferredAmount);
        return true;
    }
    function _transferMatchingBonus(address buyer,uint256 amount) internal returns (uint) {
        address parent = line[buyer];
        address child = buyer; 
        uint commAmount;
        uint totalAmountTransfer = 0;
        bool success; 
        Generation memory gen = Generation(0,0,0,0);
        uint count=0;
        while(parent != address(0))
        {   
            if (gen.Diamond == 5) {
                return totalAmountTransfer;
                // break;
            }          
            uint256 rank= ranks[parent];
            uint256 matchingRate =0;
            if (rank < 2 && count !=0 ){             
                child = parent;
                parent = line[parent];
                count++;
                continue;
            }
            if (rank> 1){              //Silver
                gen.Silver +=1;
            }
            if(rank >2){          //Gold
                gen.Gold +=1; 
            }
            if(rank>3){         //Platinum
                gen.Platinum +=1;
            }
            if(rank>4){  //Diamond
                gen.Diamond +=1;
            }
            mGenerations[parent] = gen;
            if(count==0){matchingRate += comMatchingRate[0];}
            if(gen.Silver<=2 && rank >= 2){matchingRate += comMatchingRate[1];}
            if(gen.Gold<=3 && rank >= 3){matchingRate += comMatchingRate[2];}        
            if(gen.Platinum<=4 && rank >= 4){matchingRate += comMatchingRate[3];}
            if(gen.Diamond<=5 &&  rank >= 5){matchingRate += comMatchingRate[4];}
            // Pay matching commission 
            commAmount = (matchingRate*amount) / 10**3;  
            if(matchingRate>0){
                if(isActive[parent] == false){
                    success = IMasterPool(masterPool).transferCommission(wallet, commAmount);
                    require(success, "Failed transfer matching commission"); 
                }else{
                    IMasterPool(masterPool).transferCommission(parent, commAmount);
                    emit PayBonus(parent, commAmount, block.timestamp,"Matching");            
                }
                totalAmountTransfer += commAmount;
                totalMatchingBonus[parent] += commAmount;
                totalMatchingPayment += commAmount;
            }           

            // next iteration
            child = parent;
            parent = line[parent];
            count++;
        }
        return totalAmountTransfer;
    }
    function _transferMatrixBonus(address buyer,uint256 amount) internal {
        address parent = lineMatrix[buyer];
        address child = buyer; 
        uint commAmount;
        bool success; 
        uint totalAmountTransfer = 0;
        uint maxMatrixBonus = maxMatrixRateBonus * amount / 10**3;
        // Company
        success = IMasterPool(masterPool).transferCommission(wallet, matrixCompanyRateBonus * amount / 10**3);
        require(success, "Failed transfer matrix commission"); 

        for (uint index = 0; index < maxLineForMatrixBonus; index++) 
        {   
            if (parent == address(0)) {
                success = IMasterPool(masterPool).transferCommission(wallet, maxMatrixBonus - totalAmountTransfer);
                require(success, "Failed transfer matrix commission"); 
                break;
            }
            if (_isValidLevelForMatrix(parent,index+1)) {   
                // Pay matrix commission 
                commAmount = (comMatrixRate*amount) / 10**3;             

                if(isActive[parent] == false){
                    success = IMasterPool(masterPool).transferCommission(wallet, commAmount);
                    require(success, "Failed transfer matrix commission"); 
                }else{
                    totalAmountTransfer += _transferMatchingBonus(parent,commAmount);
                    IMasterPool(masterPool).transferCommission(parent, commAmount);
                    emit PayBonus(parent, commAmount, block.timestamp,"Matrix");            
                }
                totalAmountTransfer += commAmount;
                totalMatrixBonus[parent] += commAmount;
                totalMatrixPayment += commAmount;
            }

            // next iteration
            child = parent;
            parent = lineMatrix[parent];
        }
    }

    //enum Rank {Unranked, Bronze, Silver,Gold,Platinum,Diamond,CrownDiamond}
        // Check condition of upLine with level
    function _isValidLevel(address receiver, uint atUpLine) internal view returns(bool) {
 
        if (Rank(ranks[receiver]) == Rank.Unranked && atUpLine <= 1) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Bronze && atUpLine <= 2) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Silver && atUpLine <= 4) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Gold && atUpLine <= 6) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Platinum && atUpLine <= 8) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Diamond || Rank(ranks[receiver]) == Rank.crownDiamond && atUpLine <= 10) {
            return true;   
        } else {
            return false;
        }
    }
    function _isValidLevelForMatrix(address receiver, uint atUpLine) internal view returns(bool) {
 
        if (Rank(ranks[receiver]) == Rank.Unranked && atUpLine <= 12) {
            return true;
        } else if ((Rank(ranks[receiver]) == Rank.Bronze || Rank(ranks[receiver]) == Rank.Silver) && atUpLine <= 13) {
            return true;
        } else if ((Rank(ranks[receiver]) == Rank.Gold || Rank(ranks[receiver]) == Rank.Platinum) && atUpLine <= 14) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Diamond || Rank(ranks[receiver]) == Rank.crownDiamond && atUpLine <= 15) {
            return true;   
        } else {
            return false;
        }
    }

    function _updateRank(address _address) public {
        uint256 totalMembersForUpdateLevel = _calculateTotalMemberForUpdateLevel(_address);
        uint256 totalMembersF1ForUpdateLevel = childrens[_address].length;
        uint8 rank = 0;

        if (_calculateTotalMaxMember1BranchForUpdateLevel(_address, 6) >= totalMemberRequiedToRankUps[6]){
            rank = 6;
            if (ranks[_address] < rank){
                ranks[_address] = rank;
                addCrownDiamond(_address);
            }
            return;
        }

        if (_calculateTotalMaxMember1BranchForUpdateLevel(_address, 5) >= totalMemberRequiedToRankUps[5] 
            && _calculateTotalChildWithRank(_address,4) >= RankUpdateBranchRequired){
            rank = 5;
            if (ranks[_address] < rank){
                ranks[_address] = rank;
                addDiamond(_address);
                return;
            }
            if (ranks[_address] > rank){
                ranks[_address] = rank;
                removeCrownDiamond(_address);
                return;
            }
        }

        if (_calculateTotalMaxMember1BranchForUpdateLevel(_address, 4) >= totalMemberRequiedToRankUps[4] 
            && (totalMembersF1ForUpdateLevel >= totalMemberF1RequiedToRankUps[4]
            || _calculateTotalChildWithRank(_address,3) >= RankUpdateBranchRequired)){
            rank = 4;
            if(ranks[_address] > 4){
                removeDiamond(_address);
                removeCrownDiamond(_address);
            }
            ranks[_address] = rank;
            return;
        }

        if (_calculateTotalMaxMember1BranchForUpdateLevel(_address, 3) >= totalMemberRequiedToRankUps[3] 
            && (totalMembersF1ForUpdateLevel >= totalMemberF1RequiedToRankUps[3]
            || _calculateTotalChildWithRank(_address,2) >= RankUpdateBranchRequired)){
            rank = 3;
            if(ranks[_address] > 4){
                removeDiamond(_address);
                removeCrownDiamond(_address);
            }
            ranks[_address] = rank;
            return;
        }


        if (totalMembersForUpdateLevel >= totalMemberRequiedToRankUps[2] 
            && (totalMembersF1ForUpdateLevel >= totalMemberF1RequiedToRankUps[2]
            || _calculateTotalChildWithRank(_address,1) >= RankUpdateBranchRequired)){
            rank = 2;
            if(ranks[_address] > 4){
                removeDiamond(_address);
                removeCrownDiamond(_address);
            }
            ranks[_address] = rank;
            return;
        }

        if (totalMembersForUpdateLevel >= totalMemberRequiedToRankUps[1] 
            && totalMembersF1ForUpdateLevel >= totalMemberF1RequiedToRankUps[1]){
            rank = 1;
            if(ranks[_address] > 4){
                removeDiamond(_address);
                removeCrownDiamond(_address);
            }
            ranks[_address] = rank;
            return;
        }
    }

    function _calculateTotalMemberForUpdateLevel(address _address) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < childrens[_address].length; i++) {
            total += mtotalMember[childrens[_address][i]];
            if (isActive[childrens[_address][i]]){
                total++;
            }
        }

        return total;
    }

     function _calculateTotalChildWithRank(address _address,uint8 rank) public view returns (uint256) {
        uint256 count = GetTotalChildren(_address);
        uint256 total = 0;
        address[] memory queue = new address[](count);
        uint256 front = 0;
        uint256 back = 0;
        
        for (uint256 i = 0; i < childrens[_address].length; i++) {
            queue[back] = childrens[_address][i];
            if(ranks[childrens[_address][i]] >= rank) {
                total++;
            }
            back++;
        }
        while (front < back) {
            address current = queue[front];
            front++;      
            if(childrens[current].length>0){
                for (uint256 i = 0; i < childrens[current].length; i++) {
                    queue[back] = childrens[current][i];
                    if(ranks[childrens[current][i]] >= rank) {
                        total++;
                    }
                    back++;
                }
            }         
        }
        return total;
    }

    function _calculateTotalMaxMember1BranchForUpdateLevel(address _address, uint8 level) public view returns (uint256) {        
        uint256 total = 0;

        for (uint256 i = 0; i < childrens[_address].length; i++) {
            if (isActive[childrens[_address][i]]){
                total++;
            }
            if (mtotalMember[childrens[_address][i]] > totalMaxMembers1BranchToRankUp[level]) {
                total += totalMaxMembers1BranchToRankUp[level];
            } else {
                total += mtotalMember[childrens[_address][i]];
            }
        }
        
        return total;
    }

    function GetCodeRef() external onlySub view returns(bytes32) {
        return mSubInfo[msg.sender].codeRef;
    }
    function GetSubInfo() external onlySub view returns(SubcribeInfo memory) {
        return mSubInfo[msg.sender];
    }
    
    function CheckActiveMember(address user) public view returns(bool) {
        return isActive[user];
    }

    function CheckExistMember(address _address) public view returns(bool) {
        return firstTimePay[_address] == 0;
    }

    function GetRefCodeOwner(bytes32 refCode) public view returns(address) {
        return mRefCode[refCode];
    }

    function GetHeadRef(address caller) external view returns(address) {
        return line[caller];
    }
    function TransferCommssion(address buyer, uint256 price) external onlyPackController {
        totalSale[buyer]+= price;
        _transferSaleCommission(buyer,price);
        totalSaleRevenue += price;
        _bonusForDiamond(price);
        _bonusForCrownDiamond(price);

    }
    function _transferSaleCommission(address buyer, uint256 price) internal {
        address parent = line[buyer];
        address child = buyer; 
        uint commAmount;
        bool success; 
        totalRevenues[buyer] += price;

        for (uint index = 0; index < commissionRate.length; index++) 
        {   
            if (parent == address(0)) {
                break;
            }
            if (_isValidLevel(parent,index+1)) {   
                // Pay commission by subscription
                commAmount = (commissionRate[index]*price*LNrate/10**3) / 10**3;
                if(commAmount>0){
                    if(isActive[parent] == false){
                        success = IMasterPool(masterPool).transferCommission(wallet, commAmount);
                        require(success, "Failed transfer sale commission"); 
                    }else{
                        success = IMasterPool(masterPool).transferCommission(parent, commAmount);
                        emit PayBonus(parent, commAmount, block.timestamp,"Sale");            
                        require(success, "Failed transfer sale commission"); 
                    }
                    totalUniLevelBonus[parent] += commAmount;
                    totalUniLvlPayment += commAmount;
                }
            }

            // next iteration
            child = parent;
            parent = line[parent];
        }
    }
    function SetRevenue(address add,uint256 amount)external{
        totalRevenues[add]= amount;
        totalSale[add]= amount;
    }

    function payGoodSaleBonusWeekly() external onlyAdmin returns (bool) {
        address[] memory queue = new address[](totalUser);
        uint256 front = 0;
        uint256 back = 0;
        
        // Enqueue root's children
        for (uint256 i = 0; i < childrens[root].length; i++) {
            queue[back] = childrens[root][i];
            back++;
        }

        while (front < back) {
            address current = queue[front];
            front++;

            uint256 rate = 0;
            for (uint256 j = 0; j < levelCareerBonus.length; j++) {
                if (totalRevenues[current] < levelCareerBonus[j]*usdtDecimal) {
                    break;
                } else {
                    rate += additionalCom;
                }
            }
            if(rate >0){
                // Pay commission good sale
                uint256 transferredAmount = (totalRevenues[current]*2 * rate ) / 10**3;
                bool success;
                if(isActive[current] == false){
                    success = IMasterPool(masterPool).transferCommission(wallet, transferredAmount);
                    require(success, "Failed transfer good sale bonus"); 
                }else{
                    success = IMasterPool(masterPool).transferCommission(current, transferredAmount);
                    emit PayBonus(current, transferredAmount, block.timestamp,"GoodSale");            
                    require(success, "Failed transfer good sale bonus");
                }
                totalCareerBonus[current] += transferredAmount;
                totalCareerPayment += transferredAmount;

                // Reset revenue for the current node
                totalRevenues[current] = 0;
            }
            // Enqueue current node's children
            if(childrens[current].length>0){
                for (uint256 i = 0; i < childrens[current].length; i++) {
                    queue[back] = childrens[current][i];
                    back++;
                }
            }   
       
        }
        return true;
    }

    function _bonusForDiamond(uint revenue) internal{
        uint256 len = diamondArr.length;
        bool success;
        if(len > 0){
            for(uint i=0;i<len;i++){
                uint transferredAmount = revenue * diamondRate /len/ 10**3;
                if(isActive[diamondArr[i]] == false){
                    success = IMasterPool(masterPool).transferCommission(wallet, transferredAmount);
                    require(success, "Failed transfer extra Diamond bonus"); 
                }else{
                    success = IMasterPool(masterPool).transferCommission(diamondArr[i], transferredAmount);
                    emit PayBonus(diamondArr[i], transferredAmount, block.timestamp,"Diamond");            
                    require(success, "Failed transfer extra Diamond bonus");
                }
                totalExtraDiamondBonus[diamondArr[i]] += transferredAmount;
                totalExtraDiamondPayment += transferredAmount;
            }
        } else {
            success = IMasterPool(masterPool).transferCommission(wallet, revenue * diamondRate / 10**3);
            require(success, "Failed transfer extra Diamond bonus to company");
        }
    }
    function _bonusForCrownDiamond(uint revenue) internal{
        uint256 len = crownDiamondArr.length;
        bool success;
        if(len > 0){
            for(uint i=0;i<len;i++){
                uint transferredAmount = revenue * crownDiamondRate/len / 10**3;
                if(isActive[crownDiamondArr[i]] == false){
                    success = IMasterPool(masterPool).transferCommission(wallet, transferredAmount);
                    require(success, "Failed transfer extra Crown Diamond bonus"); 
                }else{
                    success = IMasterPool(masterPool).transferCommission(crownDiamondArr[i], transferredAmount);
                    emit PayBonus(crownDiamondArr[i], transferredAmount, block.timestamp,"CrownDiamond");            
                    require(success, "Failed transfer extra Crown Diamond bonus");
                }
                totalExtraCrownDiamondBonus[crownDiamondArr[i]] += transferredAmount;
                totalExtraCrownDiamondPayment += transferredAmount;
            }
        } else {
            success = IMasterPool(masterPool).transferCommission(wallet, revenue * crownDiamondRate / 10**3);
            require(success, "Failed transfer extra Crown Diamond bonus to company"); 
        }
    }

    function GetInfoForBinaryTree(address user) external  view returns(
        uint8 rank,bytes32 phone, address[]memory children,
        uint256 _totalSubcriptionBonus,
        uint256 _totalMatrixBonus,
        uint256 _totalMatchingBonus,
        uint256 _totalUniLevelBonus,
        uint256 _totalCareerBonus,
        uint256 _totalExtraDiamondBonus,
        uint256 _totalExtraCrownDiamondBonus
        ){
        rank = ranks[user];
        phone = mphone[user];
        children = childrens[user];
        _totalSubcriptionBonus = totalSubcriptionBonus[user];
        _totalMatrixBonus = totalMatrixBonus[user];
        _totalMatchingBonus =totalMatchingBonus[user];
        _totalUniLevelBonus = totalUniLevelBonus[user];
        _totalCareerBonus = totalCareerBonus[user];
        _totalExtraDiamondBonus= totalExtraDiamondBonus[user];
        _totalExtraCrownDiamondBonus = totalExtraCrownDiamondBonus[user];
        return(
            rank,phone,children,
            _totalSubcriptionBonus,
            _totalMatrixBonus,
            _totalMatchingBonus,
            _totalUniLevelBonus,
            _totalCareerBonus,
            _totalExtraDiamondBonus,
            _totalExtraCrownDiamondBonus
            );
    }
    function GetUserInfo(address user) public  view returns(UserInfo memory userinfo){
        userinfo.add = user;
        userinfo.IsActive = isActive[user];
        userinfo.FirstTimePay = firstTimePay[user];
        userinfo.NextTimePay =nextTimePay[user];
        userinfo.Mphone = mphone[user];
        userinfo.Childrens = childrens[user];
        userinfo.ChildrensMatrix = childrensMatrix[user];
        userinfo.Line = line[user];
        userinfo.LineMatrix = lineMatrix[user];
        userinfo.MtotalMember = mtotalMember[user];
        userinfo.Rank =ranks[user];
        userinfo.totalSubcriptionBonus = totalSubcriptionBonus[user];
        userinfo.totalMatrixBonus = totalMatrixBonus[user];
        userinfo.totalMatchingBonus =totalMatchingBonus[user];
        userinfo.totalUniLevelBonus = totalUniLevelBonus[user];
        userinfo.totalCareerBonus = totalCareerBonus[user];
        userinfo.totalExtraDiamondBonus= totalExtraDiamondBonus[user];
        userinfo.totalExtraCrownDiamondBonus = totalExtraCrownDiamondBonus[user];
        userinfo.totalSale = totalSale[user];
    }

    function GetTotalChildren(address user) public view returns(uint256){
        uint256 count =0;
        count += childrens[user].length;
        for (uint256 i=0;i<childrens[user].length;i++){
            count += GetTotalChildren(childrens[user][i]);
            
        }
        return count;
    }

    function GetTotalChildrenMatrix(address user) public view returns(uint256){
        uint256 count =0;
        count += childrensMatrix[user].length;
        for (uint256 i=0;i<childrensMatrix[user].length;i++){
            count += GetTotalChildrenMatrix(childrensMatrix[user][i]);
            
        }
        return count;
    }
 function updateRankDaily() external onlyAdmin returns(bool){

        address[] memory queue = new address[](totalUser);
        uint256 front = 0;
        uint256 back = 0;
        
        // Enqueue root's children
        for (uint256 i = 0; i < childrens[root].length; i++) {
            queue[back] = childrens[root][i];
            back++;
        }

        while (front < back) {
            address current = queue[front];
            front++;
            if(nextTimePay[current]< block.timestamp && isActive[current] == true){
            // if(nextTimePay[current]< block.timestamp ){
                isActive[current] = false;
                _minusMemberLevels(current);
            }
            // Enqueue current node's children
            if(childrens[current].length>0){
                for (uint256 i = 0; i < childrens[current].length; i++) {
                    queue[back] = childrens[current][i];
                    back++;
                }
            }          
        }       
        return true;
    }
    function _minusMemberLevels(address subscriber) internal {
        address parentAddress = line[subscriber];
        while (parentAddress != address(0))
        {
            // Update quantity of member
            mtotalMember[parentAddress] -= 1;
            _updateRank(parentAddress);
            parentAddress = line[parentAddress];
        }
    }

    function addDiamond(address _address) internal {
        for (uint256 i = 0; i < diamondArr.length; i++) {
            if (diamondArr[i] == _address) {
                return;
            }
        }
        diamondArr.push(_address);
    }

    function addCrownDiamond(address _address) internal {
        for (uint256 i = 0; i < crownDiamondArr.length; i++) {
            if (crownDiamondArr[i] == _address) {
                return;
            }
        }
        crownDiamondArr.push(_address);
    }

    function removeDiamond(address value) internal {
        for (uint256 i = 0; i < diamondArr.length; i++) {
            if (diamondArr[i] == value) {
                if (i < diamondArr.length - 1) {
                    diamondArr[i] = diamondArr[diamondArr.length - 1]; // Swap with the last element
                }
                diamondArr.pop(); // Remove the last element
                return; // Exit the function after removing the element
            }
        }
    }
    function removeCrownDiamond(address value) internal {
        for (uint256 i = 0; i < crownDiamondArr.length; i++) {
            if (crownDiamondArr[i] == value) {
                if (i < crownDiamondArr.length - 1) {
                    crownDiamondArr[i] = crownDiamondArr[crownDiamondArr.length - 1]; // Swap with the last element
                }
                crownDiamondArr.pop(); // Remove the last element
                return; // Exit the function after removing the element
            }
        }
        // If the value is not found in the array, you can handle it accordingly (e.g., revert or emit an event)
    }
    function viewtree(address add) public view returns (address[] memory) {
        uint256 count = GetTotalChildren(add);
        address[] memory queue = new address[](count);
        uint256 front = 0;
        uint256 back = 0;
        
        // Enqueue root's children
        for (uint256 i = 0; i < childrens[add].length; i++) {
            queue[back] = childrens[add][i];
            back++;
        }
        while (front < back) {
            address current = queue[front];
            front++;      
            // Enqueue current node's children
            if(childrens[current].length>0){
                for (uint256 i = 0; i < childrens[current].length; i++) {
                    queue[back] = childrens[current][i];
                    back++;
                }
            }         
        }
        return queue;
    }

    function viewtreeMatrix(address add) public view returns (address[] memory) {
        uint256 count = GetTotalChildrenMatrix(add);
        address[] memory queue = new address[](count);
        uint256 front = 0;
        uint256 back = 0;
        
        // Enqueue root's children
        for (uint256 i = 0; i < childrensMatrix[add].length; i++) {
            queue[back] = childrensMatrix[add][i];
            back++;
        }
        while (front < back) {
            address current = queue[front];
            front++;      
            // Enqueue current node's children
            if(childrensMatrix[current].length>0){
                for (uint256 i = 0; i < childrensMatrix[current].length; i++) {
                    queue[back] = childrensMatrix[current][i];
                    back++;
                }
            }         
        }
        return queue;
    }

    function viewTreeInfo(address add) public view returns(UserInfo [] memory ){
        uint256 count = GetTotalChildren(add);
        address[] memory arr = viewtree(add);
        UserInfo [] memory userInfoArr = new UserInfo [](count);
        for(uint256 i=0;i<count;i++){
            UserInfo memory user =GetUserInfo(arr[i]);
            userInfoArr[i] = user;
        }
        return userInfoArr;
    }

    function viewTreeMatrixInfo(address add) public view returns(UserInfo [] memory ){
        uint256 count = GetTotalChildrenMatrix(add);
        address[] memory arr = viewtreeMatrix(add);
        UserInfo [] memory userInfoArr = new UserInfo [](count);
        for(uint256 i=0;i<count;i++){
            UserInfo memory user =GetUserInfo(arr[i]);
            userInfoArr[i] = user;
        }
        return userInfoArr;
    }
    struct ViewDirectData {
        address node;
        address parent;
    }
   
    function ViewDirect(
        address _rootAddress
    ) external view returns (ViewDirectData[] memory) {
        uint256 count = CountTotalChildren(_rootAddress, 2);
        ViewDirectData[] memory results = new ViewDirectData[](count);
        uint256 begin;
        for (uint i = 0; i < childrens[_rootAddress].length; i++) {
            results[begin] = ViewDirectData({
                node: childrens[_rootAddress][i],
                parent: _rootAddress
            });
            begin++;
            if (begin >= count) {
                return results;
            }

            for (
                uint j = 0;
                j < childrens[childrens[_rootAddress][i]].length;
                j++
            ) {
                results[begin] = ViewDirectData({
                    node: childrens[childrens[_rootAddress][i]][j],
                    parent: childrens[_rootAddress][i]
                });
                begin++;
                if (begin >= count) {
                    return results;
                }
            }
        }

        return results;
    }

    function CountTotalChildren(
        address user,
        uint generation
    ) public view returns (uint256) {
        uint256 count = 0;
        if (generation == 0) {
            return count;
        }
        count += childrens[user].length;
        for (uint256 i = 0; i < childrens[user].length; i++) {
            count += CountTotalChildren(childrens[user][i], generation - 1);
        }
        return count;
    }

    function TransferCommissionByProduct(address to, uint256 amount) external onlyPackController returns(bool) {
        return IMasterPool(masterPool).transferCommission(to, amount);
    }

    function PartnerPaymentDebt(uint256 amount) external onlyPackController returns(bool) {
        if (amount >= PartnerDebt) {
            PartnerDebt = 0;
        } else {
            PartnerDebt -= amount;
        }
        return true;
    }

    function UpdatePhone(bytes32 newPhone) external returns(bool) {
        require(newPhone != bytes32(0), "Kventure: Invalid Phone Number");
        require(mSubInfo[msg.sender].codeRef != bytes32(0), "Kventure: Not Sub");
        mSubInfo[msg.sender].phone = newPhone;
        mphone[msg.sender] = newPhone;
        return true;
    }

    function UpdateRank(address _address, uint8 rank) public returns(bool) {
        if (rank>6) {
            return false;
        }
        ranks[_address] = rank;
        
        if(rank == 5){
            diamondArr.push(_address);
            removeCrownDiamond(_address);
        }

        if(rank == 6){
            crownDiamondArr.push(_address);
            diamondArr.push(_address);
        }

        if (rank<5){
            removeCrownDiamond(_address);
            removeDiamond(_address);
        }

        return true;
    }
}