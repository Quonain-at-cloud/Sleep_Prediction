class SleepPredictionService {
    constructor() {
        // No external dependencies needed
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

        // Stress level impact
        const stress = this.getStressLevel(data);
        if (stress !== null) {
        adjustments -= (stress / 10) * 1.5;
        }

        // Dietary factors impact
        const dinnerHour = this.safeGet(data, 'Dinner Time Hour');
        if (dinnerHour !== null && dinnerHour >= 21) {
            adjustments -= 0.7;
        }

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
        const clampedStress = stress !== null ? Math.max(1, Math.min(5, stress)) : null;
        if (clampedStress !== null && clampedStress > 2) {
            analysisParts.push(`Your stress level is ${clampedStress}/5, which is not good for sleep. Try to reduce your stress.`);
        } else if (clampedStress !== null && clampedStress < 2) {
            analysisParts.push(`Your stress level is low (${clampedStress}/5), which is good for sleep.`);
        }

        // Dietary factors
        const dinnerHour = this.safeGet(data, 'Dinner Time Hour');
        if (dinnerHour !== null && !this.safeGet(data, 'Dinner Time Minute')) throw new Error('Missing required field: Dinner Time Minute');
        const dinnerMinute = this.safeGet(data, 'Dinner Time Minute');
        if (dinnerHour !== null && dinnerHour >= 21) {
            analysisParts.push(`Late dinner (at ${dinnerHour}:${dinnerMinute?.toString().padStart(2, '0')}) may be affecting your digestion during sleep`);
        }

        // Diet variety analysis
        const breakfastType = this.safeGet(data, 'Breakfast Food Type');
        if (breakfastType !== null && !this.safeGet(data, 'Lunch Food Type')) throw new Error('Missing required field: Lunch Food Type');
        const lunchType = this.safeGet(data, 'Lunch Food Type');
        if (breakfastType !== null && !this.safeGet(data, 'Dinner Food Type')) throw new Error('Missing required field: Dinner Food Type');
        const dinnerType = this.safeGet(data, 'Dinner Food Type');
        if (breakfastType !== null && breakfastType === lunchType && lunchType === dinnerType && breakfastType !== '') {
            analysisParts.push("Your diet is consistent but limited in variety, which might impact overall nutrition for sleep");
        }

        // Join analysis parts
        const detailedAnalysis = "We've analyzed your sleep data and found several factors that may affect your rest. " + analysisParts.join(". ") + ".";
        return detailedAnalysis;
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
        const temp = this.safeGet(data, 'Temperature');
        if (temp !== null && temp > 32) {
            recommendations.push(`Your room is very hot (${temp}°C)! This can severely disrupt sleep. Aim for a cool 16-20°C.`);
        } else if (temp !== null && temp > 26) {
            recommendations.push(`Your room is a bit warm (${temp}°C). Cooling it down to 16-20°C can lead to deeper, more restorative sleep.`);
        } else if (temp !== null && temp < 16) {
            recommendations.push(`Your room is cold (${temp}°C). A warmer temperature of 16-20°C is better for sleep comfort.`);
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
            if (stressLvl <= 2) {
                positiveReinforcements.push("Great job keeping your stress low before bedtime!");
            } else if (stressLvl === 3) {
                recommendations.push("Your stress level is moderate (3/5). Light relaxation practices like breathing exercises could improve sleep.");
            } else if (stressLvl === 4) {
                recommendations.push("Your stress level is high (4/5). Consider structured stress-reduction techniques such as meditation or journaling before bed.");
            } else if (stressLvl === 5) {
                recommendations.push("Your stress level is very high (5/5). Strongly consider mindfulness, progressive muscle relaxation, or consulting a professional.");
            }
        }

        // 6. Diet
        const dinnerHour = this.safeGet(data, 'Dinner Time Hour');
        if (dinnerHour !== null && dinnerHour >= 21) {
            recommendations.push("Try to have dinner earlier in the evening to improve digestion and sleep quality.");
        }

        // Combine recommendations and positive reinforcements
        return recommendations.concat(positiveReinforcements);
    }

    // Calculate contributing factors
    calculateContributingFactors(data) {
        // Five normalized contributing factors between 0 and 1
        const factors = {
            'Night Awakenings': 0,
            'Temperature': 0,
            'Noise': 0,
            'Light Intensity': 0,
            'Dietary Variety': 0,
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
        /* LEGACY FACTOR BLOCK START -- commented out to avoid duplicate code
        /* LEGACY BLOCK START
        /*
        /*
// List all possible factors
        const allFactors = [
            'Night Awakenings',
            'Device Use',
            'High Temperature',
            'Low Temperature',
            'Noise Level',
            'High Light Intensity',
            'High Stress',
            'Low Relaxation',
            'Late Dinner',
            'Dietary Variety'
        ];
        // Initialize all to 0
        const factors = {};
        allFactors.forEach(f => { factors[f] = 0; });

        // Night Awakenings
        const awakeningsCount = this.safeGet(data, 'Awakenings During Night');
        if (awakeningsCount !== null && awakeningsCount > 0) {
            analysisParts.push(`You woke up ${awakeningsCount} times during the night, which can fragment sleep.`);
        }
        const awakenings = this.safeGet(data, 'Awakenings During Night');
        if (awakenings !== null && awakenings > 0) {
            factors['Night Awakenings'] = awakenings;
        }

        // Device Use
        const deviceUse = this.safeGet(data, 'Use Electronic Devices Before Bed');
        if (deviceUse) {
            factors['Device Use'] = 0.6;
        }

        // Temperature
        const temp = this.safeGet(data, 'Temperature');
        if (temp !== null) {
        if (temp > 26) {
            factors['High Temperature'] = Math.min(0.9, (temp - 26) / 20);
        } else if (temp < 16) {
            factors['Low Temperature'] = Math.min(0.7, (16 - temp) / 10);
            }
        }

        // Noise Level
        const sound = this.safeGet(data, 'Sound Exposure');
        if (sound !== null && (sound.includes('moderate') || sound.includes('loud'))) {
            factors['Noise Level'] = 0.5;
        }

        // Light Intensity
        const light = this.safeGet(data, 'Light Intensity');
        if (light !== null) {
        if (light > 50 && light <= 200) {
            factors['High Light Intensity'] = Math.min(0.5, (light - 50) / 150);
        } else if (light > 200) {
            factors['High Light Intensity'] = 0.8;
            }
        }

        // Stress Level – always include a scaled factor (0-1 across levels 1-5)
        const stress = this.getStressLevel(data);
        const clampedStress = stress !== null ? Math.max(1, Math.min(5, stress)) : null;
        if (clampedStress !== null) {
            // Scale: 1 → 0, 5 → 1   (each step adds 0.25)
            factors['Stress Level'] = (clampedStress - 1) * 0.25;
        }

        // Relaxation Level
        const relaxation = this.safeGet(data, 'How Relaxed Before Sleep');
        if (relaxation !== null && relaxation < 3) {
            factors['Low Relaxation'] = (3 - relaxation) * 0.2;
        }

        // Late Dinner
        const dinnerHour = this.safeGet(data, 'Dinner Time Hour');
        if (dinnerHour !== null && dinnerHour >= 21) {
            factors['Late Dinner'] = 0.4;
        }

        // Dietary Variety
        const breakfastType = this.safeGet(data, 'Breakfast Food Type');
        if (breakfastType !== null && !this.safeGet(data, 'Lunch Food Type')) throw new Error('Missing required field: Lunch Food Type');
        const lunchType = this.safeGet(data, 'Lunch Food Type');
        if (breakfastType !== null && !this.safeGet(data, 'Dinner Food Type')) throw new Error('Missing required field: Dinner Food Type');
        const dinnerType = this.safeGet(data, 'Dinner Food Type');
        if (breakfastType !== null && breakfastType === lunchType && lunchType === dinnerType && breakfastType !== '') {
            factors['Dietary Variety'] = 0.1;
        }

        return factors;
    }
*/

    // Main analysis method
    analyzeSleepData(data) {
        // DEBUG: Log the input data received for prediction
        console.log('=== [DEBUG] analyzeSleepData INPUT DATA ===');
        console.log(JSON.stringify(data, null, 2));
        console.log('Sleep Duration:', data['Sleep Duration']);

        // Extract user information
        const userName = data.userName || 'there';
        const age = data.Age || 30;
        const gender = data.Gender || 'Unknown';

        // Calculate prediction score
        const predictionScore = this.calculatePredictionScore(data);
        const normalizedScore = Math.round((predictionScore / 10) * 100) / 100;

        // Calculate sleep disorder probability
        const sleepDisorderProbability = this.calculateSleepDisorderProbability(data);

        // Generate prediction summary
        const predictionSummary = this.generatePredictionSummary(predictionScore);

        // Generate detailed analysis
        const detailedAnalysis = this.generateDetailedAnalysis(data);

        // Generate sleep interruption predictions
        const { count: interruptionCount, windows: interruptionWindows } = this.predictSleepInterruptions(data, sleepDisorderProbability);

        // Generate recommendations
        const recommendations = this.generateRecommendations(data, userName);

        // Calculate contributing factors
        const contributingFactors = this.calculateContributingFactors(data);

        // Prepare response
        const response = {
            prediction: predictionSummary,
            detailedAnalysis: detailedAnalysis,
            sleepDisorderProbability: Math.round(sleepDisorderProbability * 100) / 100,
            recommendations: recommendations,
            predictionScore: Math.round(predictionScore * 10) / 10,
            normalizedScore: normalizedScore,
            predictedInterruptionCount: interruptionCount,
            predictedInterruptionWindows: interruptionWindows,
            contributingFactors: contributingFactors,
            timestamp: new Date().toISOString()
        };

        return response;
    }
}

module.exports = SleepPredictionService; 