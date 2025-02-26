# Gang Wars: Dynamic Gang Fights and Player Interaction

A FiveM resource that brings a new level of realism and excitement to your server with dynamic gang fights and player interaction. Gangs roam the streets of Los Santos, engaging in spontaneous skirmishes, defending their territories, and reacting to player actions. This script enhances the immersive experience by allowing players to influence gang dynamics, which can alter the course of gang wars and affect their outcomes.

## Features

- **Dynamic Gang Fights**: Engage in real-time gang fights that happen dynamically across the gang territories.
- **Player Interaction**: Players can interact with gang members, influencing gang wars and their outcomes.
- **Realistic Gang Behavior**: Gangs defend their territory, recruit members, and react to both player and rival gang actions.
- **Customizable**: Admins can easily configure gang territories, member behavior, and other settings to fit their server's theme.
- **Enhanced AI**: Utilizes `ox_lib` for improved AI behaviors and efficient handling of NPCs and vehicles.
- **Diverse Gangs**: Includes various gang types each with their own characteristics, from street gangs to more organized crime units.

## Dependencies

- **[ox_lib](https://github.com/overextended/ox_lib/releases)**: Required for advanced functionality like enhanced AI and efficient entity management.
- **[QBCore](https://github.com/qbcore-framework/qb-core)**: This script is designed to work with the QBCore framework, leveraging its extensive features for roleplay servers.

## Installation

1. **Download the latest release.**
2. **Extract the files to your `resources/[local]` directory in your FiveM server.**
3. **Ensure you have `ox_lib` and `QBCore` installed and properly configured on your server.**
4. **Add the resource to your server's configuration:**
   ```plaintext
   ensure gang_wars
Restart your server or use the refresh and start gang_wars commands in your server console to begin using the resource.

## Configuration

Configuring Gang Territories
Each gang's territory is defined by coordinates in the config.lua file. To change the location of a gang's territory, adjust the x, y, and z values for that gang. For example:
['Ballas'] = {
    territory = {x = 114.3, y = -1961.1, z = 21.3},
    ...
}
##Adding or Removing Vehicles
The vehicles used by each gang are also configurable. Adjust the vehicle model list to change what vehicles gang members can drive:

['Ballas'] = {
    vehicles = {'buccaneer', 'peyote', 'voodoo', 'daemon', 'hexer'}
    ...
}

##Saving Changes
After making changes in config.lua, save the file and restart your FiveM server for the changes to take effect.

##Coming Soon
More gang models and behaviors: Adding diversity and depth to the gang types available.
Improved AI and pathfinding: Enhancements to how NPCs navigate and interact with the environment.
Enhanced player interaction and influence: New ways for players to engage with and influence the gang ecosystem.

## Support
For support, feature requests, or bug reports, please submit an issue on the GitHub repository or contact us through our community support channels.

We welcome contributions from the community. If you would like to contribute to the development of this resource, please make a pull request.

License
Distributed under the MIT License. See LICENSE file for more information.
