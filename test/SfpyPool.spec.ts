import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals } from './shared/utilities'
import { poolFixture } from './shared/fixtures'
import { AddressZero } from '@ethersproject/constants'

chai.use(solidity)

describe('SfpyPool', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet], provider)

  let factory: Contract
  let token: Contract
  let pool: Contract
  beforeEach(async () => {
    const fixture = await loadFixture(poolFixture)
    factory = fixture.factory
    token = fixture.token
    pool = fixture.pool
  })

  it('mint', async () => {
    const tokenAmount = expandTo18Decimals(4)
    await token.transfer(pool.address, tokenAmount)

    const expectedLiquidity = expandTo18Decimals(2)
    await expect(pool.mint(wallet.address))
      .to.emit(pool, 'Transfer')
      .withArgs(AddressZero, wallet.address, expectedLiquidity)
      .to.emit(pool, 'Sync')
      .withArgs(tokenAmount)
      .to.emit(pool, 'Mint')
      .withArgs(wallet.address, tokenAmount)

    expect(await pool.totalSupply()).to.eq(expectedLiquidity)
    expect(await pool.balanceOf(wallet.address)).to.eq(expectedLiquidity)
    expect(await token.balanceOf(pool.address)).to.eq(tokenAmount)
    const reserves = await pool.getReserves()
    expect(reserves[0]).to.eq(tokenAmount)
  })

  it("mints multiple", async () => {
    const totalAmount = expandTo18Decimals(8)
    const tokenAmount = expandTo18Decimals(4)
    await token.transfer(pool.address, tokenAmount)

    const expectedLiquidity = expandTo18Decimals(2)
    await expect(pool.mint(wallet.address))
      .to.emit(pool, 'Transfer')
      .withArgs(AddressZero, wallet.address, expectedLiquidity)
      .to.emit(pool, 'Sync')
      .withArgs(tokenAmount)
      .to.emit(pool, 'Mint')
      .withArgs(wallet.address, tokenAmount)

    await token.transfer(pool.address, tokenAmount)
    await expect(pool.mint(other.address))
      .to.emit(pool, 'Transfer')
      .withArgs(AddressZero, other.address, expectedLiquidity)
      .to.emit(pool, 'Sync')
      .withArgs(totalAmount)
      .to.emit(pool, 'Mint')
      .withArgs(wallet.address, tokenAmount)

    expect(await pool.totalSupply()).to.eq(tokenAmount)
    expect(await pool.balanceOf(wallet.address)).to.eq(expectedLiquidity)
    expect(await pool.balanceOf(other.address)).to.eq(expectedLiquidity)
    expect(await token.balanceOf(pool.address)).to.eq(totalAmount)
    const reserves = await pool.getReserves()
    expect(reserves[0]).to.eq(totalAmount)
  })

  async function addLiquidity(tokenAmount: BigNumber) {
    await token.transfer(pool.address, tokenAmount)
    await pool.mint(wallet.address)
  }

  it('calculates liquidityToBurn', async () => {
    const tokenAmount = expandTo18Decimals(9)
    await addLiquidity(tokenAmount)
    await addLiquidity(tokenAmount)

    const expectedLiquidity = expandTo18Decimals(3)
    expect(await pool.liquidityToBurn(tokenAmount)).to.eq(expectedLiquidity)
  })

  it('burn', async () => {
    const tokenAmount = expandTo18Decimals(9)
    await addLiquidity(tokenAmount)

    const expectedLiquidity = expandTo18Decimals(3)
    await pool.transfer(pool.address, expectedLiquidity)
    await expect(pool.burn(wallet.address))
      .to.emit(pool, 'Transfer')
      .withArgs(pool.address, AddressZero, expectedLiquidity)
      .to.emit(token, 'Transfer')
      .withArgs(pool.address, wallet.address, tokenAmount)
      .to.emit(pool, 'Sync')
      .withArgs(0)
      .to.emit(pool, 'Burn')
      .withArgs(wallet.address, tokenAmount, wallet.address)

    expect(await pool.balanceOf(wallet.address)).to.eq(0)
    expect(await pool.totalSupply()).to.eq(0)
    expect(await token.balanceOf(pool.address)).to.eq(0)

    const totalSupplyToken = await token.totalSupply()
    expect(await token.balanceOf(wallet.address)).to.eq(totalSupplyToken)
  })

})