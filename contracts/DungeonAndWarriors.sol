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


contract DungeonsAndWarriors is ERC721,Ownable{



    using Counters for Counters.Counter;
    Counters.Counter counter;

    uint HpReplenishRateByMinute = 1;
    uint levelUpRateByHour = 1;
    uint damagePerHour = _random(3) + 1;
    uint8 levelUpHpModifier = 2;
     /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

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
    struct Action  { address owner; uint256 timestamp; Actions action; }

    mapping(Dungeons => LootPool) lootPools;
    mapping(uint256 => Warrior) warriors;
    mapping(uint => address) owners;
    mapping(uint => Action) currentActions;


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
        
    }

    function mint() public payable{
        counter.increment();
        _safeMint(msg.sender, counter.current());
        owners[counter.current()] = msg.sender;
        _createWarrior(counter.current());
        refundIfOver(getPrice());
    }

    function doAction(Actions _action,uint tokenId) public callerIsOwner(tokenId) {
        Action memory action = currentActions[tokenId];
        currentActions[tokenId] = Action({owner:msg.sender, timestamp: block.timestamp, action: _action});

        if(_action == Actions.RESTING){
            console.log('action1');
            //todo restore HP
        }
        else if(_action == Actions.RAIDING){
            console.log('action 0');
            //todo time locked Loot
        }
        else if(_action == Actions.TRAINING){
            console.log('action2');
            //todo level up faster
        }

        emit ActionMade(msg.sender, tokenId, block.timestamp, uint8(_action));
    }

    function claim(uint tokenId) public callerIsOwner(tokenId) {
        Action memory action = currentActions[tokenId];

        uint256 timeDiffInMinutes = (block.timestamp - action.timestamp) / 60;
        console.log('time diff in minutes',timeDiffInMinutes);
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
            warrior.hp -= (timeDiffInMinutes / 60) * damagePerHour;
            warriors[tokenId] = warrior;
            delete currentActions[tokenId];
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


    function _random(uint number) internal view returns(uint){
        return uint(blockhash(block.number-1)) % number;
    }


}