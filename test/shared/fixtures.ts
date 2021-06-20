import { Wallet, Contract } from 'ethers'
import { Web3Provider } from '@ethersproject/providers'
import { deployContract } from 'ethereum-waffle'

import { expandTo18Decimals } from './utilities'

import SfpyPool from '../../build/SfpyPool.json'
import SfpyFactory from '../../build/SfpyFactory.json'
import ERC20 from '../../build/ERC20.json'

interface FactoryFixture {
  factory: Contract
}

export async function factoryFixture([wallet]: Wallet[], _: Web3Provider): Promise<FactoryFixture> {
  const factory = await deployContract(wallet, SfpyFactory, [wallet.address])
  return { factory }
}

interface PoolFixture extends FactoryFixture {
  token: Contract
  pool: Contract
}

export async function poolFixture([wallet]: Wallet[], provider: Web3Provider): Promise<PoolFixture> {
  const { factory } = await factoryFixture([wallet], provider)

  const token = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)])

  await factory.createPool(token.address)
  const poolAddress = await factory.pool(token.address)
  const pool = new Contract(poolAddress, JSON.stringify(SfpyPool.abi), provider).connect(wallet)

  const tokenAddress = (await pool.token()).address

  return { factory, token, pool }
}