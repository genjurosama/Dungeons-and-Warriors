const { expect, assert } = require('chai');
const { ethers } = require("hardhat")

describe("Dungeons and Warriors Tests", function() {

    this.beforeEach(async function() {
        // This is executed before each test
        const DW = await ethers.getContractFactory("DungeonsAndWarriors");
        dw = await DW.deploy("DungeonsAndWarriors", "DungeonsAndWarriors" );
    })

    it("Warrior is minted successfully", async function() {
        [account1,account2] = await ethers.getSigners();
        expect(await dw.balanceOf(account1.address)).to.equal(0);
        const mintTx = await dw.connect(account1).mint({value: ethers.utils.parseEther("2.0")});
        expect(await dw.balanceOf(account1.address)).to.equal(1);
        const warrior = await  dw.connect(account1).getWarriorById(1);
        console.log('warrior:',warrior)

    })


    it("It should accept do training action and claim ", async function() {
        [account1,account2] = await ethers.getSigners();
        expect(await dw.balanceOf(account1.address)).to.equal(0);
        const mintTx = await dw.connect(account1).mint({value: ethers.utils.parseEther("2.0")});
        console.log('initial state of warrior',await  dw.connect(account1).getWarriorById(1));
        expect(await dw.balanceOf(account1.address)).to.equal(1);
        await dw.connect(account1).doAction(ethers.BigNumber.from("2"),1);
        // suppose the current block has a timestamp of 01:00 PM
        await network.provider.send("evm_increaseTime", [3600])
        await network.provider.send("evm_mine") // this one will have 02:00 PM as its timestamp
        const action = await dw.connect(account1).getCurrentAction(1);
        const claim = await dw.connect(account1).claim(1);
        expect(action.action).to.equal(2);
        const warrior = await  dw.connect(account1).getWarriorById(1);
        console.log('warrior:',warrior)

    })


    it("It should accept do raiding action and claim + rest to replenish lost HP ", async function() {
        [account1,account2] = await ethers.getSigners();
        expect(await dw.balanceOf(account1.address)).to.equal(0);
        const mintTx = await dw.connect(account1).mint({value: ethers.utils.parseEther("1.0")});
        const initialWarriorState = await  dw.connect(account1).getWarriorById(1);
        expect(await dw.balanceOf(account1.address)).to.equal(1);
        await dw.connect(account1).doAction(ethers.BigNumber.from("0"),1);
        // suppose the current block has a timestamp of 01:00 PM
        await network.provider.send("evm_increaseTime", [3600])
        await network.provider.send("evm_mine") // this one will have 02:00 PM as its timestamp
        const action = await dw.connect(account1).getCurrentAction(1);
        await dw.connect(account1).claim(1);
        expect(action.action).to.equal(0);
        const warrior2 = await  dw.connect(account1).getWarriorById(1);
        const hp = Number(warrior2.hp)
        console.log('took damage and new HP is :',hp)
        expect(hp).to.be.lte(Number(initialWarriorState.hp));
        await dw.connect(account1).doAction(ethers.BigNumber.from("1"),1);
        await network.provider.send("evm_increaseTime", [7200])
        await network.provider.send("evm_mine") // this one will have 02:00 PM as its timestamp
        await dw.connect(account1).claim(1);
        const warrior3 = await  dw.connect(account1).getWarriorById(1);
        console.log('replenished HP to :',warrior3.hp)
        expect(Number(warrior3.hp)).to.be.gt(Number(warrior2.hp));

    })


   



    
    
})