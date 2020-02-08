/* SQLEditor (MySQL (2))*/


DROP TABLE IF EXISTS `call_routes`;

DROP TABLE IF EXISTS `lcr_carrier_set_entry`;

DROP TABLE IF EXISTS `lcr_routes`;

DROP TABLE IF EXISTS `api_keys`;

DROP TABLE IF EXISTS `phone_numbers`;

DROP TABLE IF EXISTS `sip_gateways`;

DROP TABLE IF EXISTS `voip_carriers`;

DROP TABLE IF EXISTS `applications`;

DROP TABLE IF EXISTS `accounts`;

DROP TABLE IF EXISTS `service_providers`;

DROP TABLE IF EXISTS `webhooks`;

CREATE TABLE IF NOT EXISTS `call_routes`
(
`call_route_sid` CHAR(36) NOT NULL UNIQUE ,
`priority` INTEGER NOT NULL,
`account_sid` CHAR(36) NOT NULL,
`regex` VARCHAR(255) NOT NULL,
`application_sid` CHAR(36) NOT NULL,
PRIMARY KEY (`call_route_sid`)
) ENGINE=InnoDB COMMENT='a regex-based pattern match for call routing';

CREATE TABLE IF NOT EXISTS `lcr_routes`
(
`lcr_route_sid` CHAR(36),
`regex` VARCHAR(32) NOT NULL COMMENT 'regex-based pattern match against dialed number, used for LCR routing of PSTN calls',
`description` VARCHAR(1024),
`priority` INTEGER NOT NULL UNIQUE  COMMENT 'lower priority routes are attempted first',
PRIMARY KEY (`lcr_route_sid`)
) COMMENT='Least cost routing table';

CREATE TABLE IF NOT EXISTS `api_keys`
(
`api_key_sid` CHAR(36) NOT NULL UNIQUE ,
`token` CHAR(36) NOT NULL UNIQUE ,
`account_sid` CHAR(36),
`service_provider_sid` CHAR(36),
PRIMARY KEY (`api_key_sid`)
) ENGINE=InnoDB COMMENT='An authorization token that is used to access the REST api';

CREATE TABLE IF NOT EXISTS `voip_carriers`
(
`voip_carrier_sid` CHAR(36) NOT NULL UNIQUE ,
`name` VARCHAR(64) NOT NULL UNIQUE ,
`description` VARCHAR(255),
`account_sid` CHAR(36) COMMENT 'if provided, indicates this entity represents a customer PBX that is associated with a specific account',
`application_sid` CHAR(36) COMMENT 'If provided, all incoming calls from this source will be routed to the associated application',
PRIMARY KEY (`voip_carrier_sid`)
) ENGINE=InnoDB COMMENT='A Carrier or customer PBX that can send or receive calls';

CREATE TABLE IF NOT EXISTS `webhooks`
(
`webhook_sid` CHAR(36) NOT NULL UNIQUE ,
`url` VARCHAR(255) NOT NULL,
`method` ENUM("get","post") NOT NULL DEFAULT 'post',
`username` VARCHAR(255),
`password` VARCHAR(255),
PRIMARY KEY (`webhook_sid`)
) COMMENT='An HTTP callback';

CREATE TABLE IF NOT EXISTS `phone_numbers`
(
`phone_number_sid` CHAR(36) UNIQUE ,
`number` VARCHAR(255) NOT NULL UNIQUE ,
`voip_carrier_sid` CHAR(36) NOT NULL,
`account_sid` CHAR(36),
`application_sid` CHAR(36),
PRIMARY KEY (`phone_number_sid`)
) ENGINE=InnoDB COMMENT='A phone number that has been assigned to an account';

CREATE TABLE IF NOT EXISTS `lcr_carrier_set_entry`
(
`lcr_carrier_set_entry_sid` CHAR(36),
`workload` INTEGER NOT NULL DEFAULT 1 COMMENT 'represents a proportion of traffic to send through the associated carrier; can be used for load balancing traffic across carriers with a common priority for a destination',
`lcr_route_sid` CHAR(36) NOT NULL,
`voip_carrier_sid` CHAR(36) NOT NULL,
`priority` INTEGER NOT NULL DEFAULT 0 COMMENT 'lower priority carriers are attempted first',
PRIMARY KEY (`lcr_carrier_set_entry_sid`)
) COMMENT='An entry in the LCR routing list';

CREATE TABLE IF NOT EXISTS `sip_gateways`
(
`sip_gateway_sid` CHAR(36),
`ipv4` VARCHAR(32) NOT NULL COMMENT 'ip address or DNS name of the gateway.  For gateways providing inbound calling service, ip address is required.',
`port` INTEGER NOT NULL DEFAULT 5060 COMMENT 'sip signaling port',
`inbound` BOOLEAN NOT NULL COMMENT 'if true, whitelist this IP to allow inbound calls from the gateway',
`outbound` BOOLEAN NOT NULL COMMENT 'if true, include in least-cost routing when placing calls to the PSTN',
`voip_carrier_sid` CHAR(36) NOT NULL,
`is_active` BOOLEAN NOT NULL DEFAULT 1,
PRIMARY KEY (`sip_gateway_sid`)
) COMMENT='A whitelisted sip gateway used for origination/termination';

CREATE TABLE IF NOT EXISTS `applications`
(
`application_sid` CHAR(36) NOT NULL UNIQUE ,
`name` VARCHAR(255) NOT NULL,
`account_sid` CHAR(36) NOT NULL COMMENT 'account that this application belongs to',
`call_hook_sid` CHAR(36) COMMENT 'webhook to call for inbound calls to phone numbers owned by this account',
`call_status_hook_sid` CHAR(36) COMMENT 'webhook to call for call status events',
`speech_synthesis_vendor` VARCHAR(64) NOT NULL DEFAULT 'google',
`speech_synthesis_voice` VARCHAR(64) NOT NULL DEFAULT 'en-US-Wavenet-C',
`speech_recognizer_vendor` VARCHAR(64) NOT NULL DEFAULT 'google',
`speech_recognizer_language` VARCHAR(64) NOT NULL DEFAULT 'en-US',
PRIMARY KEY (`application_sid`)
) ENGINE=InnoDB COMMENT='A defined set of behaviors to be applied to phone calls ';

CREATE TABLE IF NOT EXISTS `service_providers`
(
`service_provider_sid` CHAR(36) NOT NULL UNIQUE ,
`name` VARCHAR(64) NOT NULL UNIQUE ,
`description` VARCHAR(255),
`root_domain` VARCHAR(255) UNIQUE ,
`registration_hook_sid` CHAR(36),
PRIMARY KEY (`service_provider_sid`)
) ENGINE=InnoDB COMMENT='A partition of the platform used by one service provider';

CREATE TABLE IF NOT EXISTS `accounts`
(
`account_sid` CHAR(36) NOT NULL UNIQUE ,
`name` VARCHAR(255) NOT NULL,
`sip_realm` VARCHAR(132) UNIQUE  COMMENT 'sip domain that will be used for devices registering under this account',
`service_provider_sid` CHAR(36) NOT NULL COMMENT 'service provider that owns the customer relationship with this account',
`registration_hook_sid` CHAR(36) COMMENT 'webhook to call when devices underr this account attempt to register',
`device_calling_hook_sid` CHAR(36) COMMENT 'webhook to call when devices under this account place outbound calls',
`is_active` BOOLEAN NOT NULL DEFAULT true,
PRIMARY KEY (`account_sid`)
) ENGINE=InnoDB COMMENT='An enterprise that uses the platform for comm services';

CREATE INDEX `call_routes_call_route_sid_idx` ON `call_routes` (`call_route_sid`);
ALTER TABLE `call_routes` ADD FOREIGN KEY account_sid_idxfk (`account_sid`) REFERENCES `accounts` (`account_sid`);

ALTER TABLE `call_routes` ADD FOREIGN KEY application_sid_idxfk (`application_sid`) REFERENCES `applications` (`application_sid`);

CREATE INDEX `api_keys_api_key_sid_idx` ON `api_keys` (`api_key_sid`);
CREATE INDEX `api_keys_account_sid_idx` ON `api_keys` (`account_sid`);
ALTER TABLE `api_keys` ADD FOREIGN KEY account_sid_idxfk_1 (`account_sid`) REFERENCES `accounts` (`account_sid`);

CREATE INDEX `api_keys_service_provider_sid_idx` ON `api_keys` (`service_provider_sid`);
ALTER TABLE `api_keys` ADD FOREIGN KEY service_provider_sid_idxfk (`service_provider_sid`) REFERENCES `service_providers` (`service_provider_sid`);

CREATE INDEX `voip_carriers_voip_carrier_sid_idx` ON `voip_carriers` (`voip_carrier_sid`);
CREATE INDEX `voip_carriers_name_idx` ON `voip_carriers` (`name`);
ALTER TABLE `voip_carriers` ADD FOREIGN KEY account_sid_idxfk_2 (`account_sid`) REFERENCES `accounts` (`account_sid`);

ALTER TABLE `voip_carriers` ADD FOREIGN KEY application_sid_idxfk_1 (`application_sid`) REFERENCES `applications` (`application_sid`);

CREATE INDEX `webhooks_webhook_sid_idx` ON `webhooks` (`webhook_sid`);
CREATE INDEX `phone_numbers_phone_number_sid_idx` ON `phone_numbers` (`phone_number_sid`);
CREATE INDEX `phone_numbers_voip_carrier_sid_idx` ON `phone_numbers` (`voip_carrier_sid`);
ALTER TABLE `phone_numbers` ADD FOREIGN KEY voip_carrier_sid_idxfk (`voip_carrier_sid`) REFERENCES `voip_carriers` (`voip_carrier_sid`);

ALTER TABLE `phone_numbers` ADD FOREIGN KEY account_sid_idxfk_3 (`account_sid`) REFERENCES `accounts` (`account_sid`);

ALTER TABLE `phone_numbers` ADD FOREIGN KEY application_sid_idxfk_2 (`application_sid`) REFERENCES `applications` (`application_sid`);

ALTER TABLE `lcr_carrier_set_entry` ADD FOREIGN KEY lcr_route_sid_idxfk (`lcr_route_sid`) REFERENCES `lcr_routes` (`lcr_route_sid`);

ALTER TABLE `lcr_carrier_set_entry` ADD FOREIGN KEY voip_carrier_sid_idxfk_1 (`voip_carrier_sid`) REFERENCES `voip_carriers` (`voip_carrier_sid`);

CREATE UNIQUE INDEX `sip_gateways_sip_gateway_idx_hostport` ON `sip_gateways` (`ipv4`,`port`);

ALTER TABLE `sip_gateways` ADD FOREIGN KEY voip_carrier_sid_idxfk_2 (`voip_carrier_sid`) REFERENCES `voip_carriers` (`voip_carrier_sid`);

CREATE UNIQUE INDEX `applications_idx_name` ON `applications` (`account_sid`,`name`);

CREATE INDEX `applications_application_sid_idx` ON `applications` (`application_sid`);
CREATE INDEX `applications_name_idx` ON `applications` (`name`);
CREATE INDEX `applications_account_sid_idx` ON `applications` (`account_sid`);
ALTER TABLE `applications` ADD FOREIGN KEY account_sid_idxfk_4 (`account_sid`) REFERENCES `accounts` (`account_sid`);

ALTER TABLE `applications` ADD FOREIGN KEY call_hook_sid_idxfk (`call_hook_sid`) REFERENCES `webhooks` (`webhook_sid`);

ALTER TABLE `applications` ADD FOREIGN KEY call_status_hook_sid_idxfk (`call_status_hook_sid`) REFERENCES `webhooks` (`webhook_sid`);

CREATE INDEX `service_providers_service_provider_sid_idx` ON `service_providers` (`service_provider_sid`);
CREATE INDEX `service_providers_name_idx` ON `service_providers` (`name`);
CREATE INDEX `service_providers_root_domain_idx` ON `service_providers` (`root_domain`);
ALTER TABLE `service_providers` ADD FOREIGN KEY registration_hook_sid_idxfk (`registration_hook_sid`) REFERENCES `webhooks` (`webhook_sid`);

CREATE INDEX `accounts_account_sid_idx` ON `accounts` (`account_sid`);
CREATE INDEX `accounts_name_idx` ON `accounts` (`name`);
CREATE INDEX `accounts_sip_realm_idx` ON `accounts` (`sip_realm`);
CREATE INDEX `accounts_service_provider_sid_idx` ON `accounts` (`service_provider_sid`);
ALTER TABLE `accounts` ADD FOREIGN KEY service_provider_sid_idxfk_1 (`service_provider_sid`) REFERENCES `service_providers` (`service_provider_sid`);

ALTER TABLE `accounts` ADD FOREIGN KEY registration_hook_sid_idxfk_1 (`registration_hook_sid`) REFERENCES `webhooks` (`webhook_sid`);

ALTER TABLE `accounts` ADD FOREIGN KEY device_calling_hook_sid_idxfk (`device_calling_hook_sid`) REFERENCES `webhooks` (`webhook_sid`);
