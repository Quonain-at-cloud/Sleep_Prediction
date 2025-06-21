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
  if ('weekdayBedtimeHour' in sleepData) mappedData['Weekday Bedtime Hour'] = sleepData.weekdayBedtimeHour;
  if ('weekdayBedtimeMinute' in sleepData) mappedData['Weekday Bedtime Minute'] = sleepData.weekdayBedtimeMinute;
  if ('weekdayWakeUpHour' in sleepData) mappedData['Weekday Wake-up Hour'] = sleepData.weekdayWakeUpHour;
  if ('weekdayWakeUpMinute' in sleepData) mappedData['Weekday Wake-up Minute'] = sleepData.weekdayWakeUpMinute;
  if ('weekendBedtimeHour' in sleepData) mappedData['Weekend Bedtime Hour'] = sleepData.weekendBedtimeHour;
  if ('weekendBedtimeMinute' in sleepData) mappedData['Weekend Bedtime Minute'] = sleepData.weekendBedtimeMinute;
  if ('weekendWakeUpHour' in sleepData) mappedData['Weekend Wake-up Hour'] = sleepData.weekendWakeUpHour;
  if ('weekendWakeUpMinute' in sleepData) mappedData['Weekend Wake-up Minute'] = sleepData.weekendWakeUpMinute;
  if ('awakeningsDuringNight' in sleepData) mappedData['Awakenings During Night'] = Number(sleepData.awakeningsDuringNight);
  else if ('awakenings' in sleepData) mappedData['Awakenings During Night'] = Number(sleepData.awakenings);
  if ('rateSleepQuality' in sleepData) mappedData['Rate Sleep Quality'] = sleepData.rateSleepQuality;
  if ('useElectronicDevicesBeforeBed' in sleepData) mappedData['Use Electronic Devices Before Bed'] = sleepData.useElectronicDevicesBeforeBed;
  if ('howRelaxedBeforeSleep' in sleepData) mappedData['How Relaxed Before Sleep'] = sleepData.howRelaxedBeforeSleep;
  if ('Sleep Duration' in sleepData) mappedData['Sleep Duration'] = sleepData['Sleep Duration'];
  if ('Physical Activity Level' in sleepData) mappedData['Physical Activity Level'] = sleepData['Physical Activity Level'];
  if ('Heart Rate' in sleepData) mappedData['Heart Rate'] = sleepData['Heart Rate'];
  if ('Daily Steps' in sleepData) mappedData['Daily Steps'] = sleepData['Daily Steps'];
  if ('Stress Level' in sleepData) mappedData['Stress Level'] = sleepData['Stress Level'];

  // From environmentalData
  if ('lightIntensity' in environmentalData) mappedData['Light Intensity'] = Number(environmentalData.lightIntensity);
  if ('temperature' in environmentalData) mappedData['Temperature'] = Number(environmentalData.temperature);
  if ('soundExposure' in environmentalData) mappedData['Sound Exposure'] = environmentalData.soundExposure;

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
