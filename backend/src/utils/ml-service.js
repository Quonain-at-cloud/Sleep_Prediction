// Data mapping utility for sleep prediction
// This function maps Flutter/backend data to the format expected by our Node.js prediction service

function mapSleepDataToMLInput(sleepData = {}, environmentalData = {}, dietaryData = {}) {
  // This function flattens the nested data from Flutter/backend and maps it to the
  // exact flat, space-separated key format that our Node.js service expects.
  const mappedData = {};

  // From sleepData (merging sleepPatterns and profileInfo)
  if ('userName' in sleepData) mappedData['userName'] = sleepData.userName;
  if ('Age' in sleepData) mappedData['Age'] = sleepData.Age;
  if ('Gender' in sleepData) mappedData['Gender'] = sleepData.Gender;
  if ('BMI Category' in sleepData) mappedData['BMI Category'] = sleepData['BMI Category'];
  if ('weekdayBedtimeHour' in sleepData) {
    mappedData['Weekday Bedtime Hour'] = sleepData.weekdayBedtimeHour;
  } else if ('Weekday Bedtime Hour' in sleepData) {
    mappedData['Weekday Bedtime Hour'] = sleepData['Weekday Bedtime Hour'];
  }
  if ('weekdayBedtimeMinute' in sleepData) {
    mappedData['Weekday Bedtime Minute'] = sleepData.weekdayBedtimeMinute;
  } else if ('Weekday Bedtime Minute' in sleepData) {
    mappedData['Weekday Bedtime Minute'] = sleepData['Weekday Bedtime Minute'];
  }
  if ('weekdayWakeUpHour' in sleepData) {
    mappedData['Weekday Wake-up Hour'] = sleepData.weekdayWakeUpHour;
  } else if ('Weekday Wake-up Hour' in sleepData) {
    mappedData['Weekday Wake-up Hour'] = sleepData['Weekday Wake-up Hour'];
  }
  if ('weekdayWakeUpMinute' in sleepData) {
    mappedData['Weekday Wake-up Minute'] = sleepData.weekdayWakeUpMinute;
  } else if ('Weekday Wake-up Minute' in sleepData) {
    mappedData['Weekday Wake-up Minute'] = sleepData['Weekday Wake-up Minute'];
  }
  if ('weekendBedtimeHour' in sleepData) {
    mappedData['Weekend Bedtime Hour'] = sleepData.weekendBedtimeHour;
  } else if ('Weekend Bedtime Hour' in sleepData) {
    mappedData['Weekend Bedtime Hour'] = sleepData['Weekend Bedtime Hour'];
  }
  if ('weekendBedtimeMinute' in sleepData) {
    mappedData['Weekend Bedtime Minute'] = sleepData.weekendBedtimeMinute;
  } else if ('Weekend Bedtime Minute' in sleepData) {
    mappedData['Weekend Bedtime Minute'] = sleepData['Weekend Bedtime Minute'];
  }
  if ('weekendWakeUpHour' in sleepData) {
    mappedData['Weekend Wake-up Hour'] = sleepData.weekendWakeUpHour;
  } else if ('Weekend Wake-up Hour' in sleepData) {
    mappedData['Weekend Wake-up Hour'] = sleepData['Weekend Wake-up Hour'];
  }
  if ('weekendWakeUpMinute' in sleepData) {
    mappedData['Weekend Wake-up Minute'] = sleepData.weekendWakeUpMinute;
  } else if ('Weekend Wake-up Minute' in sleepData) {
    mappedData['Weekend Wake-up Minute'] = sleepData['Weekend Wake-up Minute'];
  }
  if ('awakeningsDuringNight' in sleepData) {
    mappedData['Awakenings During Night'] = Number(sleepData.awakeningsDuringNight);
  } else if ('awakenings' in sleepData) {
    mappedData['Awakenings During Night'] = Number(sleepData.awakenings);
  } else if ('Awakenings During Night' in sleepData) {
    mappedData['Awakenings During Night'] = Number(sleepData['Awakenings During Night']);
  }
  if ('rateSleepQuality' in sleepData) mappedData['Rate Sleep Quality'] = sleepData.rateSleepQuality;
  if ('useElectronicDevicesBeforeBed' in sleepData) {
    mappedData['Use Electronic Devices Before Bed'] = sleepData.useElectronicDevicesBeforeBed;
  } else if ('Use Electronic Devices Before Bed' in sleepData) {
    mappedData['Use Electronic Devices Before Bed'] = sleepData['Use Electronic Devices Before Bed'];
  }
  if ('howRelaxedBeforeSleep' in sleepData) {
    mappedData['How Relaxed Before Sleep'] = sleepData.howRelaxedBeforeSleep;
  } else if ('How Relaxed Before Sleep' in sleepData) {
    mappedData['How Relaxed Before Sleep'] = sleepData['How Relaxed Before Sleep'];
  }
  if ('Sleep Duration' in sleepData) mappedData['Sleep Duration'] = sleepData['Sleep Duration'];
  if ('Physical Activity Level' in sleepData) mappedData['Physical Activity Level'] = sleepData['Physical Activity Level'];
  if ('Heart Rate' in sleepData) mappedData['Heart Rate'] = sleepData['Heart Rate'];
  if ('Daily Steps' in sleepData) mappedData['Daily Steps'] = sleepData['Daily Steps'];
  if ('Stress Level' in sleepData) mappedData['Stress Level'] = sleepData['Stress Level'];

  // From environmentalData
  if ('lightIntensity' in environmentalData) mappedData['Light Intensity'] = Number(environmentalData.lightIntensity);
  if ('temperature' in environmentalData) mappedData['Temperature'] = Number(environmentalData.temperature);
  if ('soundExposure' in environmentalData) mappedData['Sound Exposure'] = environmentalData.soundExposure;
  if ('noiseLevel' in environmentalData) mappedData['Noise Level'] = Number(environmentalData.noiseLevel);
  else if ('Noise Level' in environmentalData) mappedData['Noise Level'] = Number(environmentalData['Noise Level']);

  // From dietaryData
  if ('takeBreakfast' in dietaryData) mappedData['Take Breakfast'] = dietaryData.takeBreakfast;
  if ('breakfastTimeHour' in dietaryData) mappedData['Breakfast Time Hour'] = dietaryData.breakfastTimeHour;
  if ('breakfastTimeMinute' in dietaryData) mappedData['Breakfast Time Minute'] = dietaryData.breakfastTimeMinute;
  if ('breakfastFoodType' in dietaryData) mappedData['Breakfast Food Type'] = dietaryData.breakfastFoodType;
  if ('breakfastPortionSize' in dietaryData) mappedData['Breakfast Portion Size'] = dietaryData.breakfastPortionSize;
  if ('doLunch' in dietaryData) mappedData['Do Lunch'] = dietaryData.doLunch;
  if ('lunchTimeHour' in dietaryData) mappedData['Lunch Time Hour'] = dietaryData.lunchTimeHour;
  if ('lunchTimeMinute' in dietaryData) mappedData['Lunch Time Minute'] = dietaryData.lunchTimeMinute;
  if ('lunchFoodType' in dietaryData) mappedData['Lunch Food Type'] = dietaryData.lunchFoodType;
  if ('lunchPortionSize' in dietaryData) mappedData['Lunch Portion Size'] = dietaryData.lunchPortionSize;
  if ('haveDinner' in dietaryData) mappedData['Have Dinner'] = dietaryData.haveDinner;
  if ('dinnerTimeHour' in dietaryData) mappedData['Dinner Time Hour'] = dietaryData.dinnerTimeHour;
  if ('dinnerTimeMinute' in dietaryData) mappedData['Dinner Time Minute'] = dietaryData.dinnerTimeMinute;
  if ('dinnerFoodType' in dietaryData) mappedData['Dinner Food Type'] = dietaryData.dinnerFoodType;
  if ('dinnerPortionSize' in dietaryData) mappedData['Dinner Portion Size'] = dietaryData.dinnerPortionSize;
  if ('noOfMealsPerDay' in dietaryData) mappedData['No Of Meals Per Day'] = dietaryData.noOfMealsPerDay;

  // Debug log for mapped values
  console.log('[ML-MAP]', mappedData);

  return mappedData;
}

module.exports = {
  mapSleepDataToMLInput
};
