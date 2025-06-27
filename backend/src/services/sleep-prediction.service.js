class SleepPredictionService {
    constructor() {
        // No external dependencies needed
    }
    
    // Format time as HH:MM
    formatTime(h, m) {
        return `${h}:${m.toString().padStart(2, '0')}`;
    }
    
    // Enhanced Meal Timing Analysis
    analyzeMealTiming(mealType, hour, minute, data) {
        if (hour === null || minute === null) return null;
        
        const mealTime = hour + (minute / 60);
        const wakeupHour = this.safeGet(data, 'Weekday Wake-up Hour') || 7;
        const wakeupMinute = this.safeGet(data, 'Weekday Wake-up Minute') || 0;
        const wakeupTime = wakeupHour + (wakeupMinute / 60);
        
        if (mealType === 'breakfast') {
            const timeAfterWakeup = mealTime - wakeupTime;
            if (timeAfterWakeup < 0) {
                return `Breakfast at ${this.formatTime(hour, minute)} is before waking up - try eating within 2 hours of waking.`;
            } else if (timeAfterWakeup > 2) {
                return `Breakfast at ${this.formatTime(hour, minute)} is quite late (${Math.round(timeAfterWakeup*10)/10}h after waking).`;
            } else {
                return `Good breakfast timing at ${this.formatTime(hour, minute)} (${Math.round(timeAfterWakeup*10)/10}h after waking).`;
            }
        } else if (mealType === 'lunch') {
            if (mealTime < 11) {
                return `Early lunch at ${this.formatTime(hour, minute)} - consider having it between 12-2pm for better digestion.`;
            } else if (mealTime > 15) {
                return `Late lunch at ${this.formatTime(hour, minute)} - try to have it before 3pm.`;
            } else {
                return `Good lunch timing at ${this.formatTime(hour, minute)}.`;
            }
        } else if (mealType === 'dinner') {
            if (mealTime < 17) {
                return `Early dinner at ${this.formatTime(hour, minute)} - great for digestion.`;
            } else if (mealTime >= 21) {
                return `Late dinner at ${this.formatTime(hour, minute)} - try to finish 3 hours before bedtime.`;
            } else if (mealTime >= 19) {
                return `Dinner at ${this.formatTime(hour, minute)} - slightly late, but still within good range.`;
            } else {
                return `Ideal dinner timing at ${this.formatTime(hour, minute)}.`;
            }
        }
        return null;
    }
    
    // Analyze portion size (1-5 scale where 3 is ideal)
    analyzePortionSize(mealType, size) {
        if (size === null || size === undefined) return null;
        
        // Convert to number if it's a string
        const portionSize = typeof size === 'string' ? parseFloat(size) : size;
        if (isNaN(portionSize)) return null;
        
        // Convert from grams to 1-5 scale if needed
        const normalizedSize = portionSize > 10 ? 
            Math.min(5, Math.max(1, Math.round(portionSize / 100))) : 
            portionSize;
        
        const sizeRanges = [
            { max: 1.5, label: 'very small' },
            { max: 2.5, label: 'small' },
            { max: 3.5, label: 'moderate' },
            { max: 4.5, label: 'large' },
            { max: 5, label: 'very large' }
        ];
        
        let portionDesc = 'moderate';
        for (const range of sizeRanges) {
            if (normalizedSize <= range.max) {
                portionDesc = range.label;
                break;
            }
        }
        
        const portionFeedback = {
            'very small': `Your ${mealType} portion is very small. Consider increasing it for better energy.`,
            'small': `Your ${mealType} portion is small. A slightly larger portion might be more satisfying.`,
            'moderate': `Your ${mealType} portion is moderate - great for balanced nutrition.`,
            'large': `Your ${mealType} portion is large. Consider slightly smaller portions for better digestion.`,
            'very large': `Your ${mealType} portion is very large. Large meals can disrupt sleep quality.`
        };
        
        return portionFeedback[portionDesc] || '';
    }

    // Helper to safely get a field or return null
    safeGet(data, key) {
        return (key in data) ? data[key] : null;
    }

    // Helper to get stress level from user input, trying all possible keys
    getStressLevel(data) {
        for (const key of ['Stress Level', 'stressLevel', 'Stress_Level']) {
            if (key in data) {
                return data[key];
            }
        }
        return null;
    }

    // Calculate sleep duration from input data
    calculateSleepDuration(data) {
        if ('Sleep Duration' in data && data['Sleep Duration'] > 0) {
            return data['Sleep Duration'];
        }
        return null;
    }

    // Calculate prediction score (0-10 scale)
    calculatePredictionScore(data) {
        let baseScore = 7.0;
        let adjustments = 0.0;

        // Sleep duration impact (optimal is 7-9 hours)
        const sleepDuration = this.calculateSleepDuration(data);
        if (sleepDuration !== null) {
        if (sleepDuration < 6) {
            adjustments -= 1.5;
        } else if (sleepDuration < 7) {
            adjustments -= 0.5;
        } else if (sleepDuration > 9) {
            adjustments -= 0.3;
        } else {
            adjustments += 0.5; // Optimal range
            }
        }

        // Sleep quality self-rating impact
        const sleepQuality = this.safeGet(data, 'Rate Sleep Quality');
        if (sleepQuality !== null) {
        adjustments += (sleepQuality - 3) * 0.5;
        }

        // Awakenings impact
        const awakenings = this.safeGet(data, 'Awakenings During Night');
        if (awakenings !== null && awakenings > 0) {
            adjustments -= Math.min(2.0, awakenings * 0.5);
        }

        // Electronic device usage impact
        const deviceUse = this.safeGet(data, 'Use Electronic Devices Before Bed');
        if (deviceUse) {
            adjustments -= 0.7;
        }

        // Relaxation level impact
        const relaxation = this.safeGet(data, 'How Relaxed Before Sleep');
        if (relaxation !== null) {
        adjustments += (relaxation - 3) * 0.3;
        }

        // Environmental factors impact
        const temp = this.safeGet(data, 'Temperature');
        if (temp !== null && (temp < 16 || temp > 26)) {
            adjustments -= 0.5;
        }

        // Sound exposure
        const sound = (this.safeGet(data, 'Sound Exposure') || '').toLowerCase();
        if (sound.includes('loud')) {
            adjustments -= 0.8;
        } else if (sound.includes('moderate')) {
            adjustments -= 0.3;
        }

        // Light intensity (lower is better for sleep)
        const light = this.safeGet(data, 'Light Intensity');
        if (light !== null) {
        if (light > 50 && light <= 200) {
            adjustments -= 0.5;
        } else if (light > 200) {
            adjustments -= 1.0;
            }
        }

        // Physical activity impact
        const activity = this.safeGet(data, 'Physical Activity Level');
        if (activity !== null) {
        if (activity < 30) {
            adjustments -= 0.5;
        } else if (activity > 30 && activity <= 60) {
            adjustments += 0.5;
            }
        }

        // Stress level impact – balanced around level 3 (neutral). Lower stress boosts score; higher stress lowers it.
        const stress = this.getStressLevel(data);
        if (stress !== null) {
            // Stress ranges 1-5. Difference from neutral (3) times coefficient 0.4 (~±0.8 range)
            const diffFromNeutral = 3 - Number(stress);
            adjustments += diffFromNeutral * 0.4;
        }

        // Dietary factors impact
        const dinnerHour = this.safeGet(data, 'Dinner Time Hour');
        if (dinnerHour !== null && dinnerHour >= 21) {
            adjustments -= 0.7;
        }

        // ---- New dietary scoring ----
        // Number of meals per day (ideal is 3)
        const mealsPerDay = this.safeGet(data, 'No Of Meals Per Day');
        if (mealsPerDay !== null) {
            if (mealsPerDay < 3) {
                adjustments -= 0.5;
            } else if (mealsPerDay === 3) {
                adjustments += 0.2;
            } else if (mealsPerDay > 4) {
                adjustments -= 0.3;
            }
        }

        // Meal regularity, timing and portion size analysis
        const meals = [
            { 
                type: 'breakfast', 
                hasMeal: this.safeGet(data, 'Take Breakfast'),
                hour: this.safeGet(data, 'Breakfast Time Hour'),
                minute: this.safeGet(data, 'Breakfast Time Minute'),
                portion: this.safeGet(data, 'Breakfast Portion Size')
            },
            { 
                type: 'lunch', 
                hasMeal: this.safeGet(data, 'Do Lunch'),
                hour: this.safeGet(data, 'Lunch Time Hour'),
                minute: this.safeGet(data, 'Lunch Time Minute'),
                portion: this.safeGet(data, 'Lunch Portion Size')
            },
            { 
                type: 'dinner', 
                hasMeal: this.safeGet(data, 'Have Dinner'),
                hour: this.safeGet(data, 'Dinner Time Hour'),
                minute: this.safeGet(data, 'Dinner Time Minute'),
                portion: this.safeGet(data, 'Dinner Portion Size')
            }
        ];

        // Analyze each meal
        meals.forEach(meal => {
            // Penalize for skipped meals
            if (meal.hasMeal === false) {
                adjustments -= 0.4;
                return;
            }

            // Analyze meal timing
            if (meal.hour !== null) {
                const mealTime = meal.hour + (meal.minute || 0) / 60;
                
                if (meal.type === 'dinner') {
                    // Dinner should be 2-3 hours before bedtime
                    if (mealTime >= 21) { // After 9 PM
                        adjustments -= 0.5;
                    } else if (mealTime >= 20) { // 8-9 PM
                        adjustments -= 0.2;
                    } else if (mealTime >= 18) { // 6-8 PM - ideal
                        adjustments += 0.3;
                    }
                } else if (meal.type === 'breakfast') {
                    // Breakfast should be within 2 hours of waking up
                    const wakeupHour = this.safeGet(data, 'Weekday Wake-up Hour') || 7;
                    const wakeupMinute = this.safeGet(data, 'Weekday Wake-up Minute') || 0;
                    const wakeupTime = wakeupHour + (wakeupMinute / 60);
                    
                    if (mealTime - wakeupTime > 2) { // More than 2 hours after waking
                        adjustments -= 0.2;
                    } else if (mealTime - wakeupTime < 0) { // Before waking up (skipped)
                        adjustments -= 0.3;
                    } else {
                        adjustments += 0.2; // Good timing
                    }
                }
            }

            // Analyze portion size (assuming 1-5 scale where 3 is ideal)
            if (meal.portion !== null) {
                if (meal.portion <= 1) {
                    adjustments -= 0.3; // Too small
                } else if (meal.portion >= 5) {
                    adjustments -= 0.4; // Too large
                } else if (meal.portion === 3) {
                    adjustments += 0.2; // Ideal
                }
            }
        });

        // Calculate average portion size for overall impact
        const portions = meals
            .filter(m => m.portion !== null)
            .map(m => m.portion);
            
        if (portions.length > 0) {
            const avgPortion = portions.reduce((a, b) => a + b, 0) / portions.length;
            if (avgPortion < 2) {
                adjustments -= 0.2; // Overall portions too small
            } else if (avgPortion > 4) {
                adjustments -= 0.3; // Overall portions too large
            }
        }

        // Meal regularity penalties
        const mealRegularityFlags = [
            this.safeGet(data, 'Take Breakfast'),
            this.safeGet(data, 'Do Lunch'),
            this.safeGet(data, 'Have Dinner')
        ];
        mealRegularityFlags.forEach(flag => {
            if (flag === false) {
                adjustments -= 0.4;
            }
        });

        // Portion size impact based on average across meals
        const portionVals = [
            this.safeGet(data, 'Breakfast Portion Size'),
            this.safeGet(data, 'Lunch Portion Size'),
            this.safeGet(data, 'Dinner Portion Size')
        ].filter(v => v !== null && !isNaN(v));
        if (portionVals.length) {
            const avgPortion = portionVals.reduce((a, b) => a + Number(b), 0) / portionVals.length;
            if (avgPortion > 600) {
                adjustments -= 0.4;
            } else if (avgPortion < 200) {
                adjustments -= 0.3;
            } else {
                adjustments += 0.1;
            }
        }

        // --- Food type (macro & beverage) impact ---
        const foodTypeKeys = ['Breakfast Food Type', 'Lunch Food Type', 'Dinner Food Type'];
        const allFoodTypes = [];
        foodTypeKeys.forEach(k => {
            const ft = this.safeGet(data, k);
            if (ft) {
                if (Array.isArray(ft)) {
                    allFoodTypes.push(...ft.map(s => String(s).toLowerCase()));
                } else {
                    allFoodTypes.push(...String(ft).split(',').map(s => s.trim().toLowerCase()));
                }
            }
        });
        const beverageCount = allFoodTypes.filter(t => t.includes('beverage')).length;
        const proteinCount = allFoodTypes.filter(t => t.includes('protein')).length;
        const fatCount = allFoodTypes.filter(t => t.includes('fat')).length;
        const fvCount = allFoodTypes.filter(t => t.includes('fruit') || t.includes('vegetable')).length;

        if (beverageCount) adjustments -= 0.3;
        if (fvCount === 0) adjustments -= 0.4; else if (fvCount >= 2) adjustments += 0.2;
        if (proteinCount === 0) adjustments -= 0.2; else adjustments += 0.1;
        if (fatCount > 1) adjustments -= 0.2;

        // Final score calculation with bounds
        const finalScore = baseScore + adjustments;
        return Math.max(0, Math.min(10, finalScore));
    }

    // Calculate sleep disorder probability
    calculateSleepDisorderProbability(data) {
        let baseProbability = 0.2;
        let riskFactors = 0.0;

        // Sleep duration outside optimal range
        const sleepDuration = this.calculateSleepDuration(data);
        if (sleepDuration !== null) {
        if (sleepDuration < 6 || sleepDuration > 9) {
            riskFactors += 0.1;
            }
        }

        // Multiple awakenings
        const awakenings = this.safeGet(data, 'Awakenings During Night');
        if (awakenings !== null && awakenings > 1) {
            riskFactors += 0.1 * awakenings;
        }

        // Poor self-rated sleep quality
        const sleepQuality = this.safeGet(data, 'Rate Sleep Quality');
        if (sleepQuality !== null && sleepQuality < 3) {
            riskFactors += 0.1 * (3 - sleepQuality);
        }

        // Electronic device usage
        const deviceUse = this.safeGet(data, 'Use Electronic Devices Before Bed');
        if (deviceUse) {
            riskFactors += 0.05;
        }

        // Low relaxation level
        const relaxation = this.safeGet(data, 'How Relaxed Before Sleep');
        if (relaxation !== null && relaxation < 3) {
            riskFactors += 0.05 * (3 - relaxation);
        }

        // Environmental factors
        const temp = this.safeGet(data, 'Temperature');
        if (temp !== null && (temp < 16 || temp > 26)) {
            riskFactors += 0.05;
        }

        const sound = (this.safeGet(data, 'Sound Exposure') || '').toLowerCase();
        if (sound.includes('loud')) {
            riskFactors += 0.1;
        }

        const light = this.safeGet(data, 'Light Intensity');
        if (light !== null && (light > 50 && light <= 200)) {
            riskFactors += 0.07;
        } else if (light !== null && light > 200) {
            riskFactors += 0.12;
        }

        // High stress level
        const stress = this.getStressLevel(data);
        if (stress !== null && stress > 7) {
            riskFactors += 0.1;
        }

        // Age factor (risk increases with age)
        const age = this.safeGet(data, 'Age');
        if (age !== null && age > 50) {
            riskFactors += 0.05 * ((age - 50) / 10);
        }

        // Final probability calculation with bounds
        const finalProbability = baseProbability + riskFactors;
        return Math.max(0, Math.min(1, finalProbability));
    }

    // Generate prediction summary
    generatePredictionSummary(score) {
        if (score >= 8) {
            return "😊 Excellent! Your sleep quality is great!";
        } else if (score >= 6) {
            return "🙂 Good! Your sleep quality is decent but can be improved.";
        } else {
            return "😴 Your sleep quality needs attention. Let's work on it!";
        }
    }

    // Generate detailed analysis
    generateDetailedAnalysis(data) {
        const analysisParts = [];

        // Sleep duration analysis
        const sleepDuration = this.calculateSleepDuration(data);
        if (sleepDuration !== null) {
        if (sleepDuration < 7) {
            analysisParts.push(`You're averaging only ${sleepDuration} hours of sleep (slightly below the recommended 7-9 hours)`);
        } else {
            analysisParts.push(`Your sleep duration of ${sleepDuration} hours is within the healthy range`);
            }
        }

        // Sleep quality factors
        const awakenings = this.safeGet(data, 'Awakenings During Night');
        if (awakenings !== null && awakenings > 0) {
            analysisParts.push(`Night awakenings (${awakenings} times) may be reducing your deep sleep quality`);
        }

        const deviceUse = this.safeGet(data, 'Use Electronic Devices Before Bed');
        if (deviceUse !== null && deviceUse) {
            analysisParts.push("Device use before bed is likely affecting your ability to fall asleep due to blue light exposure");
        }

        const relaxation = this.safeGet(data, 'How Relaxed Before Sleep');
        if (relaxation !== null && relaxation < 3) {
            analysisParts.push(`Your relaxation level before sleep is below average (${relaxation}/5), which may be affecting sleep onset`);
        }

        // Environmental factors
        const temp = this.safeGet(data, 'Temperature');
        if (temp !== null) {
        if (temp < 10) {
            analysisParts.push(`Room temperature (${temp}°C) is very low and may disrupt sleep. Ideal is 16-26°C.`);
        } else if (temp < 16) {
            analysisParts.push(`Room temperature (${temp}°C) is low. Ideal is 16-26°C for optimal sleep.`);
        } else if (temp <= 26) {
            // Normal, no message
        } else if (temp <= 32) {
            analysisParts.push(`Room temperature (${temp}°C) is slightly high. Try to keep it within 16-26°C for best sleep.`);
        } else if (temp <= 40) {
            analysisParts.push(`Room temperature (${temp}°C) is high and may disturb your sleep. Aim for 16-26°C.`);
        } else {
            analysisParts.push(`Room temperature (${temp}°C) is very high and can seriously affect sleep quality! Cool your room to 16-26°C.`);
            }
        }

        const sound = this.safeGet(data, 'Sound Exposure');
        if (sound !== null && (sound.toLowerCase().includes('moderate') || sound.includes('loud'))) {
            analysisParts.push(`${sound} noise levels may impact your ability to rest fully`);
        }

        const light = this.safeGet(data, 'Light Intensity');
        if (light !== null) {
        if (light < 10) {
            analysisParts.push(`Your room is very dark (${light} lux), ideal for sleep.`);
        } else if (light < 50) {
            analysisParts.push(`Your room is dim (${light} lux), good for winding down before sleep.`);
        } else if (light <= 200) {
            analysisParts.push(`Your room is somewhat bright (${light} lux), try to reduce light for better sleep.`);
        } else {
            analysisParts.push(`Your room is very bright (${light} lux), strongly recommended to reduce light for sleep quality.`);
            }
        }

        // Physical factors
        const activity = this.safeGet(data, 'Physical Activity Level');
        if (activity !== null) {
        if (activity < 30) {
            analysisParts.push(`Your physical activity level (${activity} minutes) is below the recommended daily amount`);
            }
        }

        // Stress level
        const stress = this.getStressLevel(data);
        const clampedStress = stress !== null ? Math.max(1, Math.min(5, Number(stress))) : null;
        if (clampedStress !== null) {
            switch (clampedStress) {
                case 1:
                    analysisParts.push('Your stress level is very low (1/5). This is excellent for sleep – keep it up!');
                    break;
                case 2:
                    analysisParts.push('Your stress level is low (2/5). Maintaining low stress will help you fall asleep more easily.');
                    break;
                case 3:
                    analysisParts.push('Your stress level is moderate (3/5). Consider light relaxation (deep breathing, gentle stretching) before bed.');
                    break;
                case 4:
                    analysisParts.push('Your stress level is high (4/5). Try mindfulness, meditation, or journaling to wind down.');
                    break;
                case 5:
                    analysisParts.push('Your stress level is very high (5/5) and may strongly impact sleep quality. Strongly consider structured stress-reduction techniques or professional help.');
                    break;
            }
        }

        // Local format time helper
        const formatTime = (h, m) => `${h}:${m.toString().padStart(2, '0')}`;

        // Helper to parse time string (HH:MM) to {hour, minute}
        const parseTimeString = (timeStr) => {
            if (!timeStr) return { hour: null, minute: null };
            const [hour, minute] = timeStr.split(':').map(Number);
            return { hour, minute };
        };

        // Process meals from both Meals array and individual fields
        const mealData = [];
        const mealsArray = this.safeGet(data, 'Meals') || [];
        
        // Process meals from Meals array if available
        mealsArray.forEach(meal => {
            if (meal && meal.Type) {
                const mealType = meal.Type.toLowerCase();
                const time = parseTimeString(meal.Time);
                const portionSize = typeof meal['Portion Size'] === 'number' ? meal['Portion Size'] : null;
                
                mealData.push({
                    type: mealType,
                    hour: time.hour,
                    minute: time.minute,
                    portionSize: portionSize,
                    hasMeal: true
                });
            }
        });

        // If no meals from array, fall back to individual fields
        if (mealData.length === 0) {
            ['Breakfast', 'Lunch', 'Dinner'].forEach(mealType => {
                const hasMeal = this.safeGet(data, `Take ${mealType}`) !== false;
                const hour = this.safeGet(data, `${mealType} Time Hour`);
                const minute = this.safeGet(data, `${mealType} Time Minute`);
                const portionSize = this.safeGet(data, `${mealType} Portion Size`);
                
                mealData.push({
                    type: mealType.toLowerCase(),
                    hour: hour,
                    minute: minute,
                    portionSize: portionSize,
                    hasMeal: hasMeal
                });
            });
        }

        // Analyze each meal's timing and portion size
        const mealAnalyses = [];
        
        mealData.forEach(meal => {
            // Only process if the meal was actually consumed
            if (!meal.hasMeal) return;
            
            // Process meal timing
            if (meal.hour !== null && meal.minute !== null) {
                const timingAnalysis = this.analyzeMealTiming(meal.type, meal.hour, meal.minute, data);
                if (timingAnalysis) {
                    mealAnalyses.push(timingAnalysis);
                }
            }
            
            // Process portion size if available
            if (meal.portionSize !== null && meal.portionSize !== undefined) {
                const portionAnalysis = this.analyzePortionSize(meal.type, meal.portionSize);
                if (portionAnalysis) {
                    mealAnalyses.push(portionAnalysis);
                }
            }
        });
        
        // Add all meal analyses to results
        if (mealAnalyses.length > 0) {
            analysisParts.push(...mealAnalyses);
        }

        // Meal consistency and frequency
        const irregularMeals = [];
        if (this.safeGet(data, 'Take Breakfast') === false) irregularMeals.push('breakfast');
        if (this.safeGet(data, 'Do Lunch') === false) irregularMeals.push('lunch');
        if (this.safeGet(data, 'Have Dinner') === false) irregularMeals.push('dinner');
        if (irregularMeals.length) {
            analysisParts.push(`Your ${irregularMeals.join(', ')} ${irregularMeals.length > 1 ? 'are' : 'is'} often irregular; keeping set meal times can help stabilise your body clock.`);
        } else {
            analysisParts.push('Your meals are taken at fairly regular times, which is beneficial for sleep.');
        }

        // Meal frequency analysis
        const mealsPerDay = this.safeGet(data, 'No Of Meals Per Day');
        if (mealsPerDay !== null) {
            if (mealsPerDay < 3) {
                analysisParts.push(`You usually have only ${mealsPerDay} meals per day; consuming 3 balanced meals can help maintain steady energy levels for better sleep.`);
            } else if (mealsPerDay === 3) {
                analysisParts.push('You have the recommended 3 meals per day, which supports steady metabolism.');
            } else if (mealsPerDay > 4) {
                analysisParts.push(`You have about ${mealsPerDay} meals a day; frequent meals close to bedtime may disrupt sleep.`);
            }
        }

        // Food composition analysis
        const macroFoodTypes = (() => {
            const arr = [];
            ['Breakfast Food Type', 'Lunch Food Type', 'Dinner Food Type'].forEach(k => {
                const ft = this.safeGet(data, k);
                if (ft) {
                    if (Array.isArray(ft)) {
                        arr.push(...ft.map(s => String(s).toLowerCase()));
                    } else {
                        arr.push(...String(ft).split(',').map(s => s.trim().toLowerCase()));
                    }
                }
            });
            return arr;
        })();
        const beverageCount2 = macroFoodTypes.filter(t=>t.includes('beverage')).length;
        const proteinCount2 = macroFoodTypes.filter(t=>t.includes('protein')).length;
        const fatCount2 = macroFoodTypes.filter(t=>t.includes('fat')).length;
        const fvCount2 = macroFoodTypes.filter(t=>t.includes('fruit')|| t.includes('vegetable')).length;
        if (beverageCount2) analysisParts.push('Frequent beverage intake (sodas/coffee) during meals might impact your sleep quality.');
        if (proteinCount2 === 0) analysisParts.push('Your meals seem low in proteins; adequate protein supports overnight muscle repair.');
        if (fvCount2 === 0) analysisParts.push('Your meals lack fruits & vegetables which provide sleep-supporting micronutrients.');
        if (fatCount2 > 1) analysisParts.push('High-fat meal choices may slow digestion and disturb sleep.');

        // Diet variety analysis
        const breakfastType = this.safeGet(data, 'Breakfast Food Type');
        if (breakfastType !== null && !this.safeGet(data, 'Lunch Food Type')) throw new Error('Missing required field: Lunch Food Type');
        const lunchType = this.safeGet(data, 'Lunch Food Type');
        if (breakfastType !== null && !this.safeGet(data, 'Dinner Food Type')) throw new Error('Missing required field: Dinner Food Type');
        const dinnerType = this.safeGet(data, 'Dinner Food Type');
        if (breakfastType !== null && breakfastType === lunchType && lunchType === dinnerType && breakfastType !== '') {
            analysisParts.push("Your diet is consistent but limited in variety, which might impact overall nutrition for sleep");
        }

        // Format analysis with first line as regular text and rest as bullet points
        if (analysisParts.length === 0) {
            return "We've analyzed your sleep data and everything looks good!";
        }
        
        const firstLine = "We've analyzed your sleep data and found several factors that may affect your rest.";
        const bulletPoints = analysisParts.map(point => 
            point.endsWith('.') ? `• ${point}` : `• ${point}.`
        ).join('\n');
        
        return `${firstLine}\n${bulletPoints}`;
    }

    // Predict sleep interruptions
    predictSleepInterruptions(data, disorderProbability) {
        const interruptionWindows = [];

        // Only predict interruptions if probability is significant
        if (disorderProbability < 0.2) {
            return { count: 0, windows: interruptionWindows };
        }

        // Calculate number of interruptions based on probability and other factors
        let baseInterruptions = Math.floor(disorderProbability * 3); // 0-3 interruptions

        // Adjust based on self-reported awakenings
        const reportedAwakenings = this.safeGet(data, 'Awakenings During Night') || 0;
        if (reportedAwakenings > 0) {
            baseInterruptions = Math.max(baseInterruptions, reportedAwakenings);
        }

        // Limit to a reasonable number
        const interruptionCount = Math.min(3, baseInterruptions);

        // Generate interruption windows
        if (interruptionCount > 0) {
            const bedtimeHour = this.safeGet(data, 'Weekday Bedtime Hour') || 23;
            const cycleLength = 100; // minutes

            for (let i = 0; i < interruptionCount; i++) {
                const cycleNumber = i + 1;
                const minutesAfterSleep = (cycleNumber * cycleLength) + Math.floor(Math.random() * 40) - 20;

                // Calculate interruption time
                const interruptionTime = new Date();
                interruptionTime.setHours(bedtimeHour, 0, 0, 0);
                interruptionTime.setMinutes(interruptionTime.getMinutes() + minutesAfterSleep);

                // If crosses to next day
                if (bedtimeHour + Math.floor(minutesAfterSleep / 60) >= 24) {
                    interruptionTime.setDate(interruptionTime.getDate() + 1);
                }

                const startHour = interruptionTime.getHours();
                const startMinute = interruptionTime.getMinutes();

                // Duration of interruption (5-25 minutes)
                const duration = Math.floor(Math.random() * 21) + 5;

                // Calculate end time
                const endTime = new Date(interruptionTime.getTime() + duration * 60000);
                const endHour = endTime.getHours();
                const endMinute = endTime.getMinutes();

                // Add to windows
                interruptionWindows.push({
                    startTime: `${startHour.toString().padStart(2, '0')}:${startMinute.toString().padStart(2, '0')}`,
                    endTime: `${endHour.toString().padStart(2, '0')}:${endMinute.toString().padStart(2, '0')}`,
                    probability: Math.round((0.4 + (disorderProbability * 0.5)) * 100) / 100
                });
            }
        }

        return { count: interruptionCount, windows: interruptionWindows };
    }

    // Generate recommendations
    generateRecommendations(data, userName) {
        const recommendations = [];
        const positiveReinforcements = [];
        const analysisParts = [];
        const personalizedGreeting = `Dear ${userName || 'User'}, here are some personalized recommendations to help improve your sleep quality:`;

        // 1. Sleep Schedule Consistency
        const weekdayBedtime = (this.safeGet(data, 'Weekday Bedtime Hour') || 0) + (this.safeGet(data, 'Weekday Bedtime Minute') || 0) / 60;
        const weekendBedtime = (this.safeGet(data, 'Weekend Bedtime Hour') || 0) + (this.safeGet(data, 'Weekend Bedtime Minute') || 0) / 60;
        if (Math.abs(weekdayBedtime - weekendBedtime) > 1.5) {
            recommendations.push("Try to maintain a consistent sleep schedule, even on weekends, to regulate your body's internal clock.");
        } else {
            positiveReinforcements.push("Great job on maintaining a consistent sleep schedule!");
        }

        // 2. Sleep Duration
        const sleepDuration = this.calculateSleepDuration(data);
        if (sleepDuration !== null) {
        if (sleepDuration < 6) {
            recommendations.push(`Your sleep duration of ${sleepDuration} hours is very low. Aim for 7-9 hours for optimal health and performance.`);
        } else if (sleepDuration < 7) {
            recommendations.push(`You're getting ${sleepDuration} hours of sleep. Increasing it to 7-9 hours could significantly boost your energy.`);
        } else if (sleepDuration > 9) {
            recommendations.push(`While getting ${sleepDuration} hours of sleep isn't always bad, consistently oversleeping can sometimes indicate underlying issues. Ensure you feel rested.`);
        } else {
            positiveReinforcements.push(`Your sleep duration of ${sleepDuration} hours is in the ideal range. Keep it up!`);
            }
        }

        // 3. Night Awakenings
        const nightAwakenings = this.safeGet(data, 'Awakenings During Night');
        if (nightAwakenings !== null && nightAwakenings > 3) {
            recommendations.push(`You wake up about ${nightAwakenings} times per night. Consider limiting evening fluids, reducing noise/light, and practicing relaxation before bed to minimize interruptions.`);
        } else if (nightAwakenings !== null && nightAwakenings === 0) {
            positiveReinforcements.push("Great job staying asleep throughout the night!");
        }

        // 4. Environmental Factors
        const roomTemp = this.safeGet(data, 'Temperature');
        if (roomTemp !== null) {
            if (roomTemp > 32) {
                recommendations.push(`Your room is very hot (${roomTemp}°C)! This can severely disrupt sleep. Aim for a cool 16-20°C.`);
            } else if (roomTemp > 26) {
                recommendations.push(`Your room is a bit warm (${roomTemp}°C). Cooling it down to 16-20°C can lead to deeper, more restorative sleep.`);
            } else if (roomTemp < 16) {
                recommendations.push(`Your room is cold (${roomTemp}°C). A warmer temperature of 16-20°C is better for sleep comfort.`);
            }
        }

        const light = this.safeGet(data, 'Light Intensity');
        if (light !== null) {
            if (light < 10) {
                recommendations.push(`Your room is already dark (${light} lux), no need to reduce light further.`);
            } else if (light < 50) {
                recommendations.push(`Your room is dim (${light} lux), good for winding down before sleep.`);
            } else if (light <= 200) {
                recommendations.push(`Try to reduce light below 50 lux for better sleep. Current: ${light} lux.`);
            } else {
                recommendations.push(`Strongly recommended to reduce light for optimal sleep. Current: ${light} lux.`);
            }
        }

        const sound = this.safeGet(data, 'Sound Exposure');
        if (sound !== null) {
        if (sound.includes('loud')) {
            recommendations.push("Loud noise is a major sleep disruptor. Consider using earplugs or a white noise machine to block it out.");
        } else if (sound.includes('moderate')) {
            recommendations.push("Even moderate noise can affect sleep quality. A quieter environment or white noise can help.");
            }
        }

        // 4. Behavioral Factors
        const deviceUse = this.safeGet(data, 'Use Electronic Devices Before Bed');
        if (deviceUse) {
            recommendations.push("Avoid screens for at least 60 minutes before bed. The blue light can trick your brain into staying awake.");
        }

        // 5. Relaxation
        const relaxation = this.safeGet(data, 'How Relaxed Before Sleep');
        if (relaxation !== null && relaxation < 3) {
            recommendations.push("Try relaxation techniques like deep breathing or meditation before bed.");
        } else {
            positiveReinforcements.push("Good job on relaxing before sleep!");
        }

        // 6-bis. Stress-specific recommendations
        const stressLvl = this.getStressLevel(data);
        if (stressLvl !== null) {
            switch (Number(stressLvl)) {
                case 1:
                    positiveReinforcements.push('Stress level very low (1/5) – perfect for quality sleep.');
                    break;
                case 2:
                    positiveReinforcements.push('Stress level low (2/5). Nice! Keep practicing relaxing habits.');
                    break;
                case 3:
                    recommendations.push('Stress level moderate (3/5). Try light relaxation like breathing exercises or gentle yoga to unwind.');
                    break;
                case 4:
                    recommendations.push('Stress level high (4/5). Consider meditation, journaling, or a warm bath to wind down.');
                    break;
                case 5:
                    recommendations.push('Stress level very high (5/5). Strongly consider mindfulness, progressive muscle relaxation, or consulting a professional.');
                    break;
            }
        }

        // 6. Diet - Meal Analysis
        const meals = [
            { 
                label: 'breakfast', 
                hasMeal: this.safeGet(data, 'Take Breakfast'),
                hour: this.safeGet(data, 'Breakfast Time Hour'),
                minute: this.safeGet(data, 'Breakfast Time Minute'),
                portion: this.safeGet(data, 'Breakfast Portion Size')
            },
            { 
                label: 'lunch', 
                hasMeal: this.safeGet(data, 'Do Lunch'),
                hour: this.safeGet(data, 'Lunch Time Hour'),
                minute: this.safeGet(data, 'Lunch Time Minute'),
                portion: this.safeGet(data, 'Lunch Portion Size')
            },
            { 
                label: 'dinner', 
                hasMeal: this.safeGet(data, 'Have Dinner'),
                hour: this.safeGet(data, 'Dinner Time Hour'),
                minute: this.safeGet(data, 'Dinner Time Minute'),
                portion: this.safeGet(data, 'Dinner Portion Size')
            }
        ];

        // Analyze each meal's timing and portion
        meals.forEach(meal => {
            if (meal.hasMeal === false) {
                recommendations.push(`Consider having ${meal.label} regularly. Skipping meals can disrupt your metabolism and sleep patterns.`);
                return;
            }

            // Analyze meal timing
            if (meal.hour !== null) {
                const mealTime = meal.hour + (meal.minute || 0) / 60;
                
                if (meal.label === 'dinner') {
                    // Dinner should be 2-3 hours before bedtime
                    if (mealTime >= 21) { // After 9 PM
                        recommendations.push("Having dinner after 9 PM can disrupt your sleep. Try to finish dinner by 8 PM for better digestion.");
                    } else if (mealTime >= 20) { // 8-9 PM
                        recommendations.push("Consider having dinner slightly earlier (before 8 PM) to allow for better digestion before sleep.");
                    } else if (mealTime >= 18) { // 6-8 PM
                        positiveReinforcements.push("Great job having dinner at an optimal time for good sleep!");
                    }
                } else if (meal.label === 'breakfast') {
                    // Breakfast should be within 2 hours of waking up
                    const wakeupHour = this.safeGet(data, 'Weekday Wake-up Hour') || 7;
                    const wakeupMinute = this.safeGet(data, 'Weekday Wake-up Minute') || 0;
                    const wakeupTime = wakeupHour + (wakeupMinute / 60);
                    
                    if (mealTime - wakeupTime > 2) { // More than 2 hours after waking
                        recommendations.push("Try to have breakfast within 2 hours of waking up to regulate your metabolism.");
                    } else if (mealTime - wakeupTime < 0) { // Before waking up (skipped)
                        recommendations.push("Make sure to have breakfast after waking up to kickstart your metabolism.");
                    } else {
                        positiveReinforcements.push("Good job having breakfast at an optimal time after waking!");
                    }
                }
            }

            // Analyze portion size (converting to 1-5 scale if needed)
            if (meal.portion !== null) {
                // Convert portion size to 1-5 scale if it's in grams (assuming 400g is moderate/3)
                let portionSize = meal.portion;
                if (portionSize > 10) { // Likely in grams, convert to 1-5 scale
                    portionSize = Math.min(5, Math.max(1, Math.round(portionSize / 100)));
                }
                
                if (portionSize <= 1) {
                    recommendations.push(`Your ${meal.label} portion seems too small. Try increasing it for better energy levels.`);
                } else if (portionSize >= 5) {
                    recommendations.push(`Your ${meal.label} portion seems quite large. Consider slightly smaller portions for better digestion.`);
                } else if (portionSize === 3) {
                    positiveReinforcements.push(`Your ${meal.label} portion size is just right!`);
                }
            }
        });

        // Food type variety and macro/balance recommendations
        const allFoodTypes = [];
        ['Breakfast Food Type', 'Lunch Food Type', 'Dinner Food Type'].forEach(k => {
            const ft = this.safeGet(data, k);
            if (ft) {
                if (Array.isArray(ft)) {
                    allFoodTypes.push(...ft.map(s => String(s).toLowerCase()));
                } else {
                    allFoodTypes.push(...String(ft).split(',').map(s => s.trim().toLowerCase()));
                }
            }
        });
        
        const beverageCount = allFoodTypes.filter(t => t.includes('beverage')).length;
        const proteinCount = allFoodTypes.filter(t => t.includes('protein')).length;
        const fatCount = allFoodTypes.filter(t => t.includes('fat')).length;
        const fvCount = allFoodTypes.filter(t => t.includes('fruit') || t.includes('vegetable')).length;

        if (beverageCount) {
            recommendations.push('Try limiting sugary/caffeinated beverages at meals to improve sleep quality.');
        }
        if (proteinCount === 0) {
            recommendations.push('Add a source of protein to your meals for balanced nutrition that supports sleep.');
        }
        if (fvCount === 0) {
            recommendations.push('Include fruits and vegetables in your meals for vitamins and minerals that aid sleep.');
        } else if (fvCount >= 2) {
            positiveReinforcements.push('Nice job including fruits & vegetables in your diet!');
        }
        if (fatCount > 1) {
            recommendations.push('High-fat foods can slow digestion; try lighter options, especially at dinner.');
        }

        // Food type variety
        const mealTypes = [];
        ['Breakfast Food Type', 'Lunch Food Type', 'Dinner Food Type'].forEach(k => {
            const v = this.safeGet(data, k);
            if (v) mealTypes.push(...(Array.isArray(v) ? v : [v]));
        });
        
        if (mealTypes.length > 0) {
            const uniqueCnt = new Set(mealTypes.map(s => String(s).trim().toLowerCase())).size;
            if (uniqueCnt < 3) {
                recommendations.push('Adding more variety (proteins, carbs, fruits & veggies) across meals can improve sleep-supporting micronutrients.');
            } else {
                positiveReinforcements.push('Great variety in your meals – balanced nutrition supports healthy sleep!');
            }
        }

        // Keep all recommendations but consolidate similar portion size ones
        let actionableRecommendations = [];
        
        // First, add all regular recommendations
        actionableRecommendations.push(...recommendations);
        
        // Check if there are multiple portion size recommendations
        const portionRecs = recommendations.filter(rec => rec && rec.includes('portion'));
        if (portionRecs.length > 1) {
            // Remove individual portion recommendations
            actionableRecommendations = actionableRecommendations.filter(rec => !rec || !rec.includes('portion'));
            // Add a consolidated portion recommendation
            actionableRecommendations.push('Consider adjusting your meal portion sizes for better digestion and energy levels.');
        }

        // Generate detailed analysis
        let detailedAnalysis = this.generateDetailedAnalysis(data);
        
        // Ensure detailedAnalysis is an array
        if (!Array.isArray(detailedAnalysis)) {
            detailedAnalysis = [detailedAnalysis];
        }
        
        // Add any meal-related analysis from generateDetailedAnalysis
        const mealAnalysis = [];
        
        // Process each meal
        const mealAnalyses = [];
        meals.forEach(meal => {
            if (meal.hasMeal && (meal.hour !== null || meal.minute !== null)) {
                const timingAnalysis = this.analyzeMealTiming(meal.label, meal.hour, meal.minute, data);
                if (timingAnalysis) {
                    mealAnalyses.push(timingAnalysis);
                }
            }

            if (meal.hasMeal && meal.portion !== null) {
                const portionAnalysis = this.analyzePortionSize(meal.label, meal.portion);
                if (portionAnalysis) {
                    mealAnalyses.push(portionAnalysis);
                }
            }
        });
        
        // Combine all recommendations and remove duplicates while preserving order
        const allRecommendations = [];
        const seen = new Set();
        
        // Add regular recommendations first
        for (const rec of recommendations) {
            if (rec && !seen.has(rec)) {
                seen.add(rec);
                allRecommendations.push(rec);
            }
        }
        
        // Add actionable recommendations (from meal analysis, etc.)
        for (const rec of actionableRecommendations) {
            if (rec && !seen.has(rec)) {
                seen.add(rec);
                allRecommendations.push(rec);
            }
        }
        
        // Process meal analyses if any
        const processMealAnalysis = (meal) => {
            if (!meal.analysis) return;
            
            if (Array.isArray(meal.analysis)) {
                meal.analysis.forEach(analysis => {
                    if (analysis && !seen.has(analysis)) {
                        seen.add(analysis);
                        allRecommendations.push(analysis);
                    }
                });
            } else if (meal.analysis && !seen.has(meal.analysis)) {
                seen.add(meal.analysis);
                allRecommendations.push(meal.analysis);
            }
        };
        
        // Process each meal's analysis
        meals.forEach(processMealAnalysis);
        
        // Filter out any empty or undefined recommendations
        const validRecommendations = allRecommendations.filter(rec => {
            return rec && typeof rec === 'string' && rec.trim().length > 0;
        });
        
        // Format with bullet points and add personalized greeting
        const formattedRecommendations = [
            `Dear ${userName || 'User'}, here are some personalized recommendations to help improve your sleep quality:`,
            ...validRecommendations.map(rec => `• ${rec.trim()}`)
        ];
        
        // Remove any duplicates that might have been introduced during formatting
        const uniqueRecommendations = [];
        const seenFormatted = new Set();
        
        for (const rec of formattedRecommendations) {
            const cleanRec = rec.replace(/^•\s*/, '').trim();
            if (cleanRec && !seenFormatted.has(cleanRec)) {
                seenFormatted.add(cleanRec);
                uniqueRecommendations.push(rec);
            }
        }
        
        return {
            recommendations: uniqueRecommendations,
            positiveReinforcements: positiveReinforcements
        };
    }

    // Calculate contributing factors
    calculateContributingFactors(data) {
        const factors = {
            'Night Awakenings': 0,
            'Temperature': 0,
            'Noise': 0,
            'Light Intensity': 0,
            'Dietary Variety': 0
        };

        // 1. Night Awakenings – worst if ≥5
        const awakenings = this.safeGet(data, 'Awakenings During Night');
        if (awakenings !== null) {
            factors['Night Awakenings'] = Math.min(1, awakenings / 5);
        }

        // 2. Temperature – deviation from optimal 19 °C, worst when |Δ| ≥10 °C
        const temp = this.safeGet(data, 'Temperature');
        if (temp !== null) {
            factors['Temperature'] = Math.min(1, Math.abs(temp - 19) / 10);
        }

        // 3. Noise – prefer dB value, else textual exposure
        const noiseDb = this.safeGet(data, 'Noise Level');
        const soundExposure = this.safeGet(data, 'Sound Exposure');
        if (noiseDb !== null) {
            factors['Noise'] = Math.min(1, noiseDb / 80); // 80 dB is very loud
        } else if (typeof soundExposure === 'string') {
            const s = soundExposure.toLowerCase();
            if (s.includes('loud')) factors['Noise'] = 0.8;
            else if (s.includes('moderate')) factors['Noise'] = 0.5;
            else factors['Noise'] = 0.1;
        }

        // 4. Light Intensity (lux) – 50-300 range
        const lux = this.safeGet(data, 'Light Intensity');
        if (lux !== null) {
            factors['Light Intensity'] = lux < 50 ? 0 : Math.min(1, (lux - 50) / 250);
        }

        // 5. Dietary Variety – monotony increases factor
        const mealTypes = [];
        ['Breakfast Food Type', 'Lunch Food Type', 'Dinner Food Type'].forEach(k => {
            const v = this.safeGet(data, k);
            if (v) mealTypes.push(v);
        });
        if (mealTypes.length === 3) {
            const uniqueCnt = new Set(mealTypes).size; // 1 (monotonous) .. 3 (varied)
            factors['Dietary Variety'] = (3 - uniqueCnt) / 2; // 1 when all same, 0 when all different
        }

        return factors;
    }

    /**
     * Analyze sleep data and return prediction results
     * @param {Object} data - The input data for sleep prediction
     * @param {string} [userName='there'] - Optional user name for personalization
     * @returns {Object} Prediction results with analysis and recommendations
     */
    analyzeSleepData(data, userName = 'there') {
        try {
            // Calculate prediction score
            const score = this.calculatePredictionScore(data);
            
            // Calculate sleep disorder probability
            const disorderProbability = this.calculateSleepDisorderProbability(data);
            
            // Generate prediction summary
            const prediction = this.generatePredictionSummary(score);
            
            // Generate detailed analysis
            const detailedAnalysis = this.generateDetailedAnalysis(data);
            
            // Predict sleep interruptions
            const interruptionPredictions = this.predictSleepInterruptions(data, disorderProbability);
            
            // Calculate contributing factors
            const contributingFactors = this.calculateContributingFactors(data);
            
            // Generate recommendations and positive reinforcements
            const { 
                recommendations, 
                positiveReinforcements 
            } = this.generateRecommendations(data, userName);
            
            // Prepare response
            return {
                prediction,
                detailedAnalysis,
                recommendations,
                positiveReinforcements,
                score,
                disorderProbability,
                interruptionPredictions,
                contributingFactors,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            console.error('Error in analyzeSleepData:', error);
            throw new Error('Failed to analyze sleep data: ' + error.message);
        }
    }
}

module.exports = SleepPredictionService;