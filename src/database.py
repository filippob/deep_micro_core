# database.py

import enum

from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    Enum,
    ForeignKey,
    UniqueConstraint,
    JSON,
    func,
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy import event

from . import project_directory

DATABASE_URL = f"sqlite:///{project_directory}/data/datasets.sqlite3"
engine = create_engine(DATABASE_URL, echo=False)


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
    variable_region = Column(String(50), nullable=True, comment="16S/18S/ITS")
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

    samples = relationship("Sample", back_populates="dataset")
    param = relationship("Param", back_populates="dataset", uselist=False)

    __table_args__ = (
        UniqueConstraint(
            "description",
            "specie_substrate",
            "tissue",
            name="_description_specie_tissue_uc",
        ),
    )

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
        return f"Dataset {self.id}: {self.description} ({self.project}, {self.tissue})"

    @classmethod
    def find_by_fw_primer(cls, session, primer_value):
        """Find datasets by FW_primer value"""
        return (
            session.query(cls)
            .join(Param)
            .filter(func.json_extract(Param.params, "$.FW_primer") == primer_value)
            .all()
        )

    @classmethod
    def find_by_json_key(cls, session, json_path, value):
        """Trova dataset con un valore JSON specifico"""
        return (
            session.query(cls)
            .join(Param)
            .filter(func.json_extract(Param.params, json_path) == value)
            .all()
        )


class Sample(Base):
    __tablename__ = "samples"

    id = Column(Integer, primary_key=True)
    dataset_id = Column(Integer, ForeignKey("datasets.id"))
    folder_name = Column(String)
    sample_id = Column(String)
    forward_reads = Column(String)
    reverse_reads = Column(String)

    dataset = relationship("Dataset", back_populates="samples")

    __table_args__ = (
        UniqueConstraint("dataset_id", "sample_id", name="_dataset_sample_uc"),
    )

    def __repr__(self):
        return (
            f"<Sample(id={self.id}, dataset_id={self.dataset_id}, folder_name={self.folder_name}, "
            f"sample_id={self.sample_id}, forward_reads={self.forward_reads}, reverse_reads={self.reverse_reads})>"
        )

    def __str__(self):
        return f"Sample {self.id}: {self.folder_name} ({self.sample_id})"


class Param(Base):
    __tablename__ = "params"

    id = Column(Integer, primary_key=True)
    dataset_id = Column(Integer, ForeignKey("datasets.id"), unique=True, nullable=False)
    params = Column(JSON, nullable=False)  # Store parameters as JSON

    dataset = relationship("Dataset", back_populates="param")

    def __repr__(self):
        return (
            f"<Param(id={self.id}, dataset_id={self.dataset_id}, params={self.params})>"
        )

    def __str__(self):
        return (
            f"Param {self.id}: FW_primer='{self.params.get('FW_primer')}', "
            f"RV_primer='{self.params.get('RV_primer')}', truncq={self.params.get('truncq')}, "
            f"trunclenf={self.params.get('trunclenf')}, trunclenr={self.params.get('trunclenr')}, "
            f"trunc_qmin={self.params.get('trunc_qmin')}, trunc_rmin={self.params.get('trunc_rmin')}, "
            f"max_ee={self.params.get('max_ee')}, min_len={self.params.get('min_len')}, "
            f"max_len={self.params.get('max_len')}"
        )


# creating all tables at once
def init_db():
    Base.metadata.create_all(engine)


# create a session
Session = sessionmaker(bind=engine)


# get the session as a function
def get_session():
    return Session()
