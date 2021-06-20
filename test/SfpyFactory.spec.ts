import chai, { expect } from 'chai'
import { Contract } from 'ethers'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'

import { getCreate2Address, getInitCodeHash } from './shared/utilities'
import { factoryFixture } from './shared/fixtures'

import SfpyPool from '../build/SfpyPool.json'

chai.use(solidity)

const TEST_ADDRESS: string = '0x1000000000000000000000000000000000000000'
const INIT_CODE_HASH: string = '0x299fc1dd996bb3989ecb29cbe15651bd653d7f3cba7229ed963bff23482465bc'

describe('SfpyFactory', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet, other], provider)

  let factory: Contract
  beforeEach(async () => {
    const fixture = await loadFixture(factoryFixture)
    factory = fixture.factory
  })

  it('owner, pools', async () => {
    expect(await factory.owner()).to.eq(wallet.address)
    expect(await factory.pools()).to.eq(0)
  })

  it('initCodeHash', async () => {
    const bytecode = `0x${SfpyPool.evm.bytecode.object}`;
    const hash = getInitCodeHash(bytecode)
    expect(hash).to.eq(INIT_CODE_HASH)
  })

  async function createPool(token: string) {
    const bytecode = `0x${SfpyPool.evm.bytecode.object}`
    const create2Address = getCreate2Address(factory.address, token, bytecode)

    await expect(factory.connect(other).createPool(token)).to.be.revertedWith('SFPY: FORBIDDEN')

    await expect(factory.createPool(token))
      .to.emit(factory, 'PoolCreated')
      .withArgs(TEST_ADDRESS, create2Address)

    await expect(factory.createPool(token)).to.be.reverted // SFPY: POOL_EXISTS
    expect(await factory.pool(token)).to.eq(create2Address)
    expect(await factory.pools()).to.eq(1)

    const pool = new Contract(create2Address, JSON.stringify(SfpyPool.abi), provider)
    expect(await pool.factory()).to.eq(factory.address)
    expect(await pool.token()).to.eq(TEST_ADDRESS)
  }

  it('createPool', async () => {
    await createPool(TEST_ADDRESS)
  })

  it('createPool:gas', async () => {
    const tx = await factory.createPool(TEST_ADDRESS)
    const receipt = await tx.wait()
    expect(receipt.gasUsed).to.eq(1900123)
  })

  it('setOwner', async () => {
    await expect(factory.connect(other).setOwner(other.address)).to.be.revertedWith('SFPY: FORBIDDEN')
    await factory.setOwner(other.address)
    expect(await factory.owner()).to.eq(other.address)
    await expect(factory.setOwner(wallet.address)).to.be.revertedWith('SFPY: FORBIDDEN')
  })

})