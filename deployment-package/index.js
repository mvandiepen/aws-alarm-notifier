const axios = require('axios')

exports.handler = async (event) => {
  const sns_message = JSON.parse(event['Records'][0]['Sns']['Message']);

  const [serverName, ...subjectParts] = sns_message.AlarmName.split('-'); // alarm name: demo-status-check
  const subject = subjectParts.join('_');


  const messageSubjects = {
    status_check: `Server ${serverName} has failed the EC2 status check for the past ${sns_message.Trigger.EvaluationPeriods} minutes. Please investigate.`,
    cpu_utilization: `Server ${serverName} has been using more than ${sns_message.Trigger.Threshold}% CPU for the past ${sns_message.Trigger.EvaluationPeriods} minutes. Please investigate.`,
    cloudwatch_agent_cpu_utilization: `Server ${serverName} has been using more than ${sns_message.Trigger.Threshold}% CPU for the past ${sns_message.Trigger.Period} seconds. Please investigate.`,
  }

  let message;

  if (sns_message.NewStateValue === 'OK') {
    message = [`:white_check_mark:  *${serverName}*`, `All is well, ${subject} issue has been resolved`].join('\n');
  } else if (sns_message.NewStateValue === 'ALARM') {
    message = [`:bangbang: *${serverName}*`, messageSubjects[subject]].join('\n');
  } else {
    return {statusCode: 201}
  }

  return axios.post(process.env.slack_webhook_url, {
    headers: {
      'Content-Type': 'application/json'
    },
    channel: process.env.slack_channel,
    username: 'Alarm Notifier',
    text: message,
  }).then(() => {
    return {statusCode: 201}
  }).catch((error) => {
    console.error(error)
    return {statusCode: 500, body: JSON.stringify(error)}
  })
};
