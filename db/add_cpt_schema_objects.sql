CREATE TABLE activity_line_items  (
	id                	int(11) AUTO_INCREMENT NOT NULL,
	object_key        	varchar(12) NOT NULL,
	capital_project_id	int(11) NOT NULL,
	team_ali_code_id  	int(11) NOT NULL,
	name              	varchar(80) NOT NULL,
	anticipated_cost  	int(11) NOT NULL,
	estimated_cost    	int(11) NULL,
	cost_justification	text NULL,
	active            	tinyint(1) NULL,
	created_at        	datetime NULL,
	updated_at        	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX activity_line_items_idx2 USING BTREE
	ON activity_line_items(capital_project_id)
GO
CREATE INDEX activity_line_items_idx1 USING BTREE
	ON activity_line_items(capital_project_id, object_key)
GO
CREATE TABLE activity_line_items_assets  (
	id                   	int(11) AUTO_INCREMENT NOT NULL,
	activity_line_item_id	int(11) NOT NULL,
	asset_id             	int(11) NOT NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX activity_line_items_assets_idx1 USING BTREE
	ON activity_line_items_assets(activity_line_item_id, asset_id)
GO

CREATE TABLE capital_project_types  (
	id         	int(11) AUTO_INCREMENT NOT NULL,
	name       	varchar(64) NOT NULL,
	code       	varchar(4) NOT NULL,
	description	varchar(254) NOT NULL,
	active     	tinyint(1) NOT NULL,
	PRIMARY KEY(id)
)
GO
CREATE TABLE capital_projects  (
	id                            	int(11) AUTO_INCREMENT NOT NULL,
	object_key                    	varchar(12) NOT NULL,
	fy_year                       	int(11) NOT NULL,
	project_number                	varchar(32) NOT NULL,
	organization_id               	int(11) NOT NULL,
	team_ali_code_id              	int(11) NOT NULL,
	capital_project_type_id       	int(11) NOT NULL,
	state                           varchar(32) NOT NULL,
	title                         	varchar(80) NOT NULL,
	description                   	varchar(254) NULL,
	justification                 	varchar(254) NULL,
	emergency                     	tinyint(1) NULL,
	active                        	tinyint(1) NULL,
	created_at                    	datetime NULL,
	updated_at                    	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX capital_projects_idx1 USING BTREE
	ON capital_projects(organization_id, object_key)
GO
CREATE INDEX capital_projects_idx2 USING BTREE
	ON capital_projects(organization_id, project_number)
GO
CREATE INDEX capital_projects_idx3 USING BTREE
	ON capital_projects(organization_id, fy_year)
GO
CREATE INDEX capital_projects_idx4 USING BTREE
	ON capital_projects(organization_id, capital_project_type_id)
GO
CREATE TABLE milestone_types  (
	id                 	int(11) AUTO_INCREMENT NOT NULL,
	name               	varchar(64) NOT NULL,
	description        	varchar(255) NOT NULL,
	is_vehicle_delivery	tinyint(1) NOT NULL,
	active             	tinyint(1) NOT NULL,
	PRIMARY KEY(id)
)
GO
CREATE TABLE milestones  (
	id                   	int(11) AUTO_INCREMENT NOT NULL,
	object_key           	varchar(12) NOT NULL,
	activity_line_item_id	int(11) NOT NULL,
	milestone_type_id    	int(11) NOT NULL,
	milestone_date       	date NULL,
	comments             	varchar(254) NULL,
	created_by_id        	int(11) NULL,
	created_at           	datetime NULL,
	updated_at           	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX milestones_idx1 USING BTREE
	ON milestones(activity_line_item_id, object_key)
GO
CREATE INDEX milestones_idx2 USING BTREE
	ON milestones(activity_line_item_id, milestone_date)
GO
CREATE TABLE funding_plans  (
	id                   	int(11) AUTO_INCREMENT NOT NULL,
	object_key           	varchar(12) NOT NULL,
	activity_line_item_id	int(11) NOT NULL,
	funding_source_id    	int(11) NOT NULL,
	amount        				int(11) NOT NULL,
	created_at           	datetime NULL,
	updated_at           	datetime NULL,
	PRIMARY KEY(id)
)
GO
CREATE INDEX funding_plans_idx1 ON funding_plans(object_key)
GO
CREATE INDEX funding_plans_idx2 ON funding_plans(activity_line_item_id, funding_source_id)
GO
