# Leaderboards

## Overview
Leaderboards track player performance across different aspects of the game, from individual levels to overall coding mastery. 

## Per-Level Scores

### Speed

**Description**: Time taken to finish the level

**Calculation**:
$\text{Speed} = (\text{End Time}) - (\text{Start Time})$

**Rules**:
- Only valid if the final submitted code has no errors
- Measured in seconds
- Lower values are better
- Tracks fastest level completion time
- $\text{End Time}$ is the time when the player defeats the Enemy.
- $\text{Start Time}$ is the time when the player starts the game.

### Accuracy

**Description**: How many mistakes you made

**Calculation**:
$\text{Accuracy} = (\text{Correct Lines}) - (\text{Error Count})$

**Rules**:
- Counts all syntax and logic errors
- Higher values are better
- Measures code quality and correctness
- $Error Count$ is the sum of all Errors whenever the code is run.

## Normalized Scores (0-100 Scale)

### Normalized Speed

**Description**: How close you are to the world record

**Calculation**:
$\text{Normalized Speed} = 100 \times \frac{\text{Your Time}}{\text{Fastest Time}}$

**Rules**:
- 100 = world record
- 50 = twice as slow as record
- 0 = took much longer than record
- Used for level rankings
- $\text{Fastest Time}$ is the fastest time in users who completed that level.

### Normalized Accuracy

**Description**: How close you are to perfect accuracy

**Calculation**:
$\text{Normalized Accuracy} = 100 \times \frac{\text{Your Accuracy}}{\text{Best Accuracy}}$

**Rules**:
- 100 = perfect accuracy
- 0 = made errors in every line
- Used for level rankings
- $\text{Best Accuracy}$ is the fastest time in users who completed that level.

## Mastery Scores

### Proficiency

**Description**: Your average skill in a programming topic

**Calculation**:
$\text{Proficiency} = \frac{\text{Sum of Normalized Scores}}{\text{Number of Levels}}$

**Rules**:
- Averaged Normalized Speed, Accuracy and Efficiency by the number of levels.
- $\text{Number of Levels}$ is number of levels completed by that player.
- Max 100 points per level

## Leaderboard Types

1. **Level Leaderboards**
	- Ranks players on specific levels
	- Uses: Normalized Speed, Accuracy, and Efficiency scores
	- Shows best performance for each level

1. **Global Leaderboard**
	- Ranks overall player skill
	- Uses: Overall Mastery score
	- Shows best overall programmers
