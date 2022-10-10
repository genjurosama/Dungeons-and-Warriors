const { expect, assert } = require('chai');
const { ethers } = require("hardhat")

describe("Dungeons and Warriors Tests", function() {

    this.beforeEach(async function() {
        // This is executed before each test
        const DW = await ethers.getContractFactory("DungeonsAndWarriors");
        dw = await DW.deploy("DungeonsAndWarriors", "DungeonsAndWarriors");
    })

    it("Warrior is minted successfully", async function() {
        [account1,account2] = await ethers.getSigners();
        expect(await dw.balanceOf(account1.address)).to.equal(0);
        const mintTx = await dw.connect(account1).mint({value: ethers.utils.parseEther("1.0")});
        expect(await dw.balanceOf(account1.address)).to.equal(1);
        const warrior = await  dw.connect(account1).getWarriorById(1);
        console.log('warrior:',warrior)

    })


    it("It should accept do action", async function() {
        [account1,account2] = await ethers.getSigners();
        expect(await dw.balanceOf(account1.address)).to.equal(0);
        const mintTx = await dw.connect(account1).mint({value: ethers.utils.parseEther("1.0")});
        expect(await dw.balanceOf(account1.address)).to.equal(1);
        await dw.connect(account1).doAction(ethers.BigNumber.from("0"),1);
        const action = await dw.connect(account1).getCurrentAction(1);
        expect(action.action).to.equal(0);
    
    })




    
    
})