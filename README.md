# sfpy-core
Core smart contracts of sfpy

In-depth documentation on sfpy is available at [sfpy.co](https://sfpy.co/docs).

# Local Development

The following assumes the use of `node@>=10`.

## Install Dependencies

`yarn`

## Compile Contracts

`yarn compile`

## Run Tests

`yarn test`

# Generating markdown references from smart contracts

`solidity-docgen` is used to generate documentation and is loaded into the package.json, meaning if you run `yarn` it will be available to use.
But if you need to install it you can follow this command

`yarn add solidity-docgen`

Get the correct compiler version. `solc` is already loaded into the package.json, meaning if you run `yarn` it will be available to use.
But if you need to install it you can follow this command

`yarn add solc`

There is already a template named `contract.hbs` inside the `/templates` folder located in the same directory as `/contracts`. 
You can edit this file or replace it with your own. Put the updated template `contract.hbs` in the `/templates` folder under the same 
directory as `/contracts` that you want to generate

Run `npx solidity-docgen --solc-module solc -t ./contracts/templates`
