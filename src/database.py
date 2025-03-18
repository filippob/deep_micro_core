# database.py

import enum

from sqlalchemy import create_engine, Column, Integer, String, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy import event

from . import project_directory

DATABASE_URL = f"sqlite:///{project_directory}/data/datasets.sqlite3"
engine = create_engine(DATABASE_URL, echo=True)


# setting pragmas for SQLite
def set_pragmas(dbapi_conn, connection_record):
    cursor = dbapi_conn.cursor()
    cursor.execute("PRAGMA synchronous = FULL")
    cursor.execute("PRAGMA journal_mode = WAL")
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.close()


# register the event listener (apply pragmas on each new connection)
event.listen(engine, "connect", set_pragmas)

# create a base class for our models (will create tables relying on classes)
Base = declarative_base()


# declare enum objects
class VariableRegionEnum(enum.Enum):
    V3V4 = "V3-V4"
    V1V2 = "V1-V2"


class StatusEnum(enum.Enum):
    published = "published"
    unpublished = "unpublished"


class Dataset(Base):
    __tablename__ = "datasets"

    id = Column(Integer, primary_key=True)
    description = Column(String)
    project = Column(String)
    year = Column(Integer)
    type_technology = Column(String(50))
    variable_region = Column(Enum(VariableRegionEnum), comment="16S/18S/ITS")
    specie_substrate = Column(String(50))
    population = Column(String(50))
    tissue = Column(String(50))
    experiment = Column(String)
    n_samples = Column(Integer)
    link = Column(String)
    data_repository = Column(String)
    project_id = Column(String)
    status = Column(Enum(StatusEnum), default=StatusEnum.unpublished)
    internal_id = Column(String(50))
    notes = Column(String)
    fwd_primer = Column(String(50))
    rev_primer = Column(String(50))
    adapter_fwd = Column(String(50))
    adapter_rev = Column(String(50))

    def __repr__(self):
        return (
            f"<Dataset(id={self.id}, description={self.description}, project={self.project}, "
            f"year={self.year}, type_technology={self.type_technology}, variable_region={self.variable_region}, "
            f"specie_substrate={self.specie_substrate}, population={self.population}, tissue={self.tissue}, "
            f"experiment={self.experiment}, n_samples={self.n_samples}, link={self.link}, "
            f"data_repository={self.data_repository}, project_id={self.project_id}, status={self.status}, "
            f"internal_id={self.internal_id}, notes={self.notes}, fwd_primer={self.fwd_primer}, "
            f"rev_primer={self.rev_primer}, adapter_fwd={self.adapter_fwd}, adapter_rev={self.adapter_rev})>"
        )

    def __str__(self):
        return f"Dataset {self.id}: {self.description} ({self.project}, {self.year})"


# creating all tables at once
def init_db():
    Base.metadata.create_all(engine)


# create a session
Session = sessionmaker(bind=engine)


# get the session as a function
def get_session():
    return Session()
