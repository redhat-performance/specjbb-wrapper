import pydantic
import datetime
class Specjbb_Results(pydantic.BaseModel):
    Warehouses: int = pydantic.Field(gt=0)
    Bops: int = pydantic.Field(gt=0)
    Numb_JVMs: int = pydantic.Field(gt=0)
    Start_Date: datetime.datetime
    End_Date: datetime.datetime
