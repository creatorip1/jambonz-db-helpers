const test = require('tape').test ;
const config = require('config');
const mysqlOpts = config.get('mysql');

process.on('unhandledRejection', (reason, p) => {
  console.log('Unhandled Rejection at: Promise', p, 'reason:', reason);
});

test('lookup auth hook tests', async(t) => {
  const fn = require('..');
  const {lookupAuthHook} = fn(mysqlOpts);
  try {
    let result = await lookupAuthHook('customerA.mycompany.com');
    //console.log(`result: ${JSON.stringify(result)}`);
    t.ok(result.url === 'http://127.0.0.1:3000', 'looks up auth hook at account level');
    result = await lookupAuthHook('subdomain.example.com');
    t.ok(result.url === 'http://127.0.0.1:4000', 'looks up auth hook at service provider level');
    result = await lookupAuthHook('subdomain.drachtio.org');
    //console.log(`result: ${JSON.stringify(result)}`);
    t.ok(result.url === 'http://127.0.0.1:4000' && result.auth.username === 'foo', 
      'looks up auth hook that has basic auth info');
    result = await lookupAuthHook('subdomain.none.org');
    t.ok(result === null, 'returns null if none found');

    
    t.end();
  }
  catch (err) {
    console.error(err);
    t.end(err);
  }
});

