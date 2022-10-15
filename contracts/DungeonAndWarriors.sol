// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract DungeonsAndWarriors is ERC721,Ownable{



    using Counters for Counters.Counter;
    Counters.Counter counter;

    uint HpReplenishRateByMinute = 1;
    uint levelUpRateByHour = 1;
    uint damagePerHour = _random(3) + 1;
    uint8 levelUpHpModifier = 2;
    uint256 SEED_NONCE = 0;
    
     /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => Trait[]) public traitTypes;   
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;
    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }

    
    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);
    enum Dungeons { DRAGONSDEN,TOXICSWAMPS, MAGMACRATER }
    
     struct LootPool { 
        uint8  minLevel; uint8  minLootTier; uint16 total;
        uint16 tier1;   uint16 tier2;      uint16 tier3; uint16 tier4;
    }

    struct Warrior {
        uint head;
        uint chest;
        uint legs;
        uint hand;
        uint offhand;
        uint hp;
        uint maxHp;
        uint level;
    }


    enum Actions {RAIDING,RESTING,TRAINING}
    struct Action  { address owner; uint256 timestamp; Actions action; Dungeons currentDungeon; }
    struct Loot {string name;}
    mapping(Dungeons => LootPool) lootPools;
    mapping(uint8 => Loot) lootList;
    mapping(address => Loot[]) lootOwned;
    mapping(uint256 => Warrior) warriors;
    mapping(uint => address) owners;
    mapping(uint => Action) currentActions;
    //uint arrays
    uint16[][1] TIERS;




    /*///////////////////////////////////////////////////////////////
                MODIFIERS
    //////////////////////////////////////////////////////////////*/


    modifier callerIsOwner (uint tokenId) {
        require(owners[tokenId] == msg.sender,"You don't own this token");
        _;
    }



    constructor(string memory name, string memory symbol) ERC721(name,symbol) {
        LootPool memory dragonsDen = LootPool({minLevel : 0, minLootTier: 1,total: 1000,tier1: 800, tier2: 100,tier3: 70,tier4: 30});
        LootPool memory toxicSwamps = LootPool({minLevel : 4, minLootTier: 4,total: 1000,tier1: 800, tier2: 100,tier3: 70,tier4: 30});
        LootPool memory magmaCrater = LootPool({minLevel : 10, minLootTier: 10,total: 1000,tier1: 800, tier2: 100,tier3: 70,tier4: 30});

        lootPools[Dungeons.DRAGONSDEN] = dragonsDen;
        lootPools[Dungeons.TOXICSWAMPS] = toxicSwamps;
        lootPools[Dungeons.MAGMACRATER] = magmaCrater;
         //loot
        TIERS[0] = [200, 300, 400, 500, 600, 900, 1200, 5700];
        lootList[7] = Loot({name:"coin"});
        lootList[6] = Loot({name:"junk"});
        lootList[5] = Loot({name:"sword"});
        lootList[4] = Loot({name:"knife"});
        lootList[3] = Loot({name:"gem"});
        lootList[2] = Loot({name:"robe"});
        lootList[1] = Loot({name:"magic wand"});
        lootList[0] = Loot({name:"legendary Sword"});
        
    }

    function mint() public payable{
        counter.increment();
        uint256 count = counter.current();
        _safeMint(msg.sender, count);
        owners[counter.current()] = msg.sender;
        _createWarrior(count);
        refundIfOver(getPrice());
    }

    function doAction(Actions _action,uint tokenId,Dungeons dungeon) public callerIsOwner(tokenId) {
        if(_action == Actions.RESTING){
            
            //todo restore HP
        }
        else if(_action == Actions.RAIDING){
            Warrior memory warrior = warriors[tokenId];
            require(warrior.level >= lootPools[dungeon].minLevel ,"Warrior's level is low for this dungeon");

            //todo time locked Loot
        }
        else if(_action == Actions.TRAINING){
            //todo level up faster
        }

        Action memory action = currentActions[tokenId];
        currentActions[tokenId] = Action({owner:msg.sender, timestamp: block.timestamp, action: _action, currentDungeon : dungeon});


        emit ActionMade(msg.sender, tokenId, block.timestamp, uint8(_action));
    }

    function claim(uint tokenId) public callerIsOwner(tokenId) {
        Action memory action = currentActions[tokenId];

        uint256 timeDiffInMinutes = (block.timestamp - action.timestamp) / 60;
        if(action.action == Actions.RESTING){
            Warrior memory warrior = warriors[tokenId] ;
            uint addedHp = timeDiffInMinutes * HpReplenishRateByMinute;
            console.log('hp to be added',addedHp);
            console.log('formula for hP',(warrior.hp + addedHp) > warrior.maxHp ? warrior.maxHp : warrior.hp + addedHp);
            warrior.hp = (warrior.hp + addedHp) > warrior.maxHp ? warrior.maxHp : warrior.hp + addedHp;
            warriors[tokenId] = warrior;
            delete currentActions[tokenId];
        }
        if(action.action == Actions.TRAINING){
            Warrior memory warrior = warriors[tokenId] ;
            console.log('time diff in hours',(timeDiffInMinutes / 60) );
            warrior.level += (timeDiffInMinutes / 60) * levelUpRateByHour;
            warrior.maxHp = warrior.maxHp  * levelUpHpModifier;
            warriors[tokenId] = warrior;
            delete currentActions[tokenId];
        }

        if(action.action == Actions.RAIDING){
            Warrior memory warrior = warriors[tokenId] ;
            uint256 dmg = (timeDiffInMinutes / 60) * damagePerHour;
            warrior.hp -= dmg;
            console.log('damage taken is :',dmg);
            warriors[tokenId] = warrior;
            delete currentActions[tokenId];
            uint8 lootIndex =rarityGen(_random(10000), 0);
            console.log('loot index',lootIndex);
            lootOwned[msg.sender].push(lootList[lootIndex]);
            Loot memory loot = lootList[lootIndex];
            console.log('Congratulations you got some loot:',loot.name );

            
        }
        
    }

    function getCurrentAction(uint tokenId) public view  returns (Action memory) {
        return currentActions[tokenId];
    }

    function _replenishHp (uint tokenId) internal {

    }

    function _createWarrior(uint256 tokenId) internal {
        warriors[tokenId] = Warrior({head:_random(3),chest:_random(3),legs:_random(3),hand:_random(3),offhand:_random(3),hp: 50,maxHp: 50,level: 1});
    }

    function getWarriorById(uint256 tokenId) public view returns(Warrior memory){
        return warriors[tokenId];
    }

    function getPrice() public pure returns (uint256) {
        return 1 ether;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }


    function getLoot() public view returns(Loot[] memory) {
        return lootOwned[msg.sender];
    }

    function _random(uint number) internal view returns(uint){
        return uint(blockhash(block.number-1)) % number;
    }



    function rarityGen(uint256 _randinput, uint8 _rarityTier)
    internal
    view
    returns (uint8)
    {
    uint16 currentLowerBound = 0;
    for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
        uint16 thisPercentage = TIERS[_rarityTier][i];
        console.log('rand input',_randinput);
        console.log('currentLowerBound',currentLowerBound);
        console.log('currentLowerBound + thisPercentage',currentLowerBound + thisPercentage);
        if (
            _randinput >= currentLowerBound &&
            _randinput < currentLowerBound + thisPercentage
        ) {
            return i;}
        currentLowerBound = currentLowerBound + thisPercentage;
    }

    revert();
    }
        


    

}