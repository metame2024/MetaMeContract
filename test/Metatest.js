const { expect } = require("chai");
const { ethers } = require("hardhat");


async function expectR(promise, expectedError){
  try{
      await promise
    }catch(error){
      let index = error.message.indexOf(expectedError)
      if(index === -1){
        expect.fail('Do not have error msg');
      }
      return
    }
    expect.fail('Expected an exception but none was received');
}

function BN(no){
  return ethers.BigNumber.from(no)
}

describe("ERC20", function () {
  it("tt", async function () {
    const [owner, team, dao, user1, user2] = await ethers.getSigners();
    //部署合约

    const TOKEN = await ethers.getContractFactory("MetaMe")
    const token = await TOKEN.deploy()
    const METAT = await ethers.getContractFactory("MetaT")
    const metaT = await METAT.deploy(token.address)
    
//查询余额

    await token.transfer(team.address, BN(200000000).mul(BN(10).pow(18)))
    await token.transfer(dao.address, BN(100000000).mul(BN(10).pow(18)))
    await token.transfer(metaT.address, BN(500000000).mul(BN(10).pow(18)))
    const tokenBalance = await token.balanceOf(owner.address)
    console.log("owner token balance:" + tokenBalance.toString())
    const teamBalance = await token.balanceOf(team.address)
    console.log("team token balance:" + teamBalance.toString())
    const daoBalance = await token.balanceOf(dao.address)
    console.log("dao token balance:" + daoBalance.toString())
    const TBalance = await token.balanceOf(metaT.address)
    console.log("MetaT token balance:" + TBalance.toString())
    await metaT.sendToken(user1.address,BN(40000000).mul(BN(10).pow(18)))
    let reward = await metaT.reward()
    let minted = await metaT.minted()
    console.log("reward amount:" + reward.toString())
    console.log("minted amount:" + minted.toString())
    await metaT.sendToken(user1.address,BN(10000000).mul(BN(10).pow(18)))
    reward = await metaT.reward()
    minted = await metaT.minted()
    console.log("reward amount:" + reward.toString())
    console.log("minted amount:" + minted.toString())

    await metaT.sendToken(user1.address,BN(60000000).mul(BN(10).pow(18)))
    reward = await metaT.reward()
    minted = await metaT.minted()
    console.log("reward amount:" + reward.toString())
    console.log("minted amount:" + minted.toString())



  });
});
