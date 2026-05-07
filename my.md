npm install

npm run dev



http://localhost:3000/health



$body = '{"studentMessage":"你好"}'

$encodedBody = \[System.Text.Encoding]::UTF8.GetBytes($body)



Invoke-RestMethod `

&#x20; -Method Post `

&#x20; -Uri "http://localhost:3000/api/chat" `

&#x20; -ContentType "application/json; charset=utf-8" `

&#x20; -Body $encodedBody



