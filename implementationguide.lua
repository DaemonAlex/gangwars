# Gang Wars Implementation Guide

This document provides a comprehensive overview of the improvements made to the Gang Wars script and how to effectively implement it on your FiveM server.

## Key Improvements

### 1. Enhanced Gang Territories
- **Visual Indicators**: Gang territories now have visible markers, blips, and props to make them easily identifiable
- **Territory Recognition**: Players are now notified when entering/exiting gang territories
- **Custom Colors**: Each gang has distinctive colors for their territory markers

### 2. Smarter Gang Members
- **Improved Targeting**: Gang members now only attack rival gangs and players who attack them
- **Gang Affiliation**: Members recognize players in their own gang and won't attack them
- **Configurable Behavior**: Each gang has unique weapons, clothing, and idle animations
- **Resource Management**: Optimized spawning and cleanup to minimize server impact

### 3. Gang Membership System
- **Player Affiliation**: Players can join and leave gangs with proper tracking
- **War Escalation**: Player actions can trigger gang wars with appropriate notifications
- **Gang Recognition**: Gang members recognize friendly players

### 4. Reputation System
- **Gang Progression**: Players can build reputation within their gang
- **Benefits & Rewards**: Higher reputation unlocks better gear and abilities
- **Action-based Reputation**: Gain or lose reputation based on your actions

## Setup Instructions

### Configuration Setup

1. **Gang Territories**:
   - Each gang has territory points defined in the config
   - Add more points to expand a gang's territory
   - Adjust the `TerritoryRadius` to control the size of territories

2. **Gang Appearance**:
   - Configure clothing for consistent gang member appearance
   - Set colors for map indicators
   - Add props to make territories visually distinct

3. **Behavior Settings**:
   - Configure weapons and combat behavior
   - Set idle animations and scenarios for ambient gang members
   - Adjust war triggers and cooldowns

### Commands

The script includes several useful commands:

| Command | Description | Usage |
|---------|-------------|-------|
| `/joingang [gang]` | Join a specific gang | `/joingang Ballas` |
| `/leavegang` | Leave your current gang | `/leavegang` |
| `/checkgangs` | List available gangs and your status | `/checkgangs` |
| `/spawngang [gang]` | Spawn gang members near you (testing) | `/spawngang Vagos` |
| `/forcespawn [gang]` | Force spawn gang members (admin) | `/forcespawn Triads` |
| `/testwar [gang]` | Trigger a gang war (admin) | `/testwar Families` |
| `/teleport [gang]` | Teleport to a gang territory | `/teleport Madrazo` |

### Gang Wars Mechanics

1. **Automatic Wars**:
   - Wars trigger randomly at configured intervals
   - Proximity between rival gang members can trigger wars
   - Player attacks on gang members can escalate to wars

2. **War Behavior**:
   - Gang members become more aggressive during wars
   - Notifications alert players to ongoing conflicts
   - Gang-affiliated players receive special alerts

3. **Ambient Gang Presence**:
   - Gang members spawn in their territories
   - They engage in configured scenarios/animations
   - Territory props create visual ambience

## Performance Optimization

To ensure your server runs smoothly with this script:

1. **Entity Management**:
   - Gang members are automatically cleaned up after a configurable time
   - Optimize the `despawnTime` in config for your server population

2. **Spawn Density**:
   - Adjust `minPeds` and `maxPeds` to control gang density
   - Lower these values on high-population servers

3. **Check Frequency**:
   - The script has optimized check frequencies
   - War triggers have appropriate cooldowns to prevent spam

4. **Visual Indicators**:
   - Map blips are configured efficiently
   - Territory markers only render when players are nearby

## Tips for Roleplay Servers

For roleplay-focused servers:

1. **Territory Control**:
   - Gang territories can become central to roleplay scenarios
   - Consider implementing territory capture mechanics

2. **Gang Hierarchy**:
   - Use the reputation system to create gang hierarchies
   - Higher-reputation members can lead operations

3. **Police Interaction**:
   - The script notifies police jobs about gang activity
   - This creates natural law enforcement interaction opportunities

4. **Economy Integration**:
   - Consider adding drug sales or other activities in territories
   - Tie gang membership to illegal business opportunities

## Troubleshooting

Common issues and solutions:

1. **Gang Members Not Spawning**:
   - Check territory coordinates are correctly set
   - Ensure models are valid and exist in your game files

2. **Gang Members Attack Own Gang**:
   - Verify relationship group setup is working
   - Check player's gang metadata is saving correctly

3. **Territory Markers Not Appearing**:
   - Check color configuration is valid
   - Ensure blip IDs are correct for your game version

4. **High Resource Usage**:
   - Lower spawn counts and check frequencies
   - Reduce the number of visual indicators

## Future Expansion Ideas

1. **Territory Capture System**
   - Allow gangs to fight for and claim new territories
   - Dynamic territory boundaries based on gang activity

2. **Gang Businesses**
   - Add specific business opportunities in territories
   - Gang-controlled shops or services

3. **Reputation Rewards**
   - Expand the reputation system with unique rewards
   - Special vehicles, weapons, or abilities

4. **Dynamic Events**
   - Random events in territories like drug shipments
   - Police raids on gang territories

---

## Implementation Checklist

- [ ] Install updated script files
- [ ] Configure gang territories and appearance
- [ ] Adjust spawn settings for your server population
- [ ] Test gang behavior with different player interactions
- [ ] Set up appropriate commands for admins and players
- [ ] Create server rules around gang gameplay
- [ ] Monitor performance and adjust as needed
